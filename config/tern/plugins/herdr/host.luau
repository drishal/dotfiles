-- Host half: the Herdr sidebar block (machines, spaces, agents, menu) and the tab strip block that
-- sits above the sidebar's terminal. Both draw natively and drive the linked terminal pane.

local common = require("./common")
local ui = tern.ui

local POLL_MS = 1500
local BRANCH_EVERY = 10 -- polls between git branch refreshes

local DOT = { blocked = "●", working = "●", done = "●", idle = "○" }

---------------------------------------------------------------------------------------------------
-- Shared

local function alive(pane: number): boolean
	for _, p in tern.pane.list() do
		if p.pane == pane then
			return true
		end
	end
	return false
end

local function el(tag: string, class: string, text: string?, children: { Node }?, click: string?): Node
	local props: { [string]: any } = { class = class }
	if text then
		props.text = text
	end
	if click then
		props.actions = { click = click }
	end
	return ui.el(tag, props, children)
end

local function dot(status: string): Node
	local node = el("span", "hs-dot", DOT[status] or "·")
	local p = node.p :: { [string]: any }
	p.attrs = { ["data-state"] = status }
	return node
end

local function linked_term(link: string): number?
	local term = tern.kv.get("link:" .. link)
	if type(term) == "number" and alive(term) then
		return term
	end
	return nil
end

local function err_text(res: any): string
	local ok, doc = pcall(tern.json.decode, res.stdout)
	if ok and type(doc) == "table" and doc.error then
		return tostring(doc.error.message or doc.error)
	end
	return (string.gsub(res.stderr .. res.stdout, "%s+$", ""))
end

-- Runs `herdr ARGS` on `machine`; `done` gets the decoded result.
local function herdr(cx: EffectCx, machine: string, args: { string }, done: ((any) -> ())?)
	tern.process.run(common.argv(machine, args), { timeout_ms = 10000 }, function(res)
		local ok, doc = pcall(tern.json.decode, res.stdout)
		if res.status ~= 0 or not ok or type(doc) ~= "table" or doc.error then
			cx:toast("error", "herdr " .. args[1] .. " " .. (args[2] or "") .. " failed", err_text(res))
			return
		end
		if done then
			done(doc.result)
		end
	end)
end

-- Shows a Herdr terminal in the link's pane, splitting one off `beside` when there is none.
local function show_terminal(cx: EffectCx, link: string, beside: number, machine: string, terminal_id: string)
	local term = linked_term(link)
	common.retarget(link, term, machine, terminal_id, tern.pane.write)
	if term then
		return
	end
	local argv = { common.tern, "split", tostring(beside), "right", "--json", "--", "sh",
		tern.plugin.dir .. "/follow.sh", common.target_file(link), common.herdr }
	tern.process.run(argv, { timeout_ms = 10000 }, function(res)
		if res.status ~= 0 then
			cx:toast("error", "Could not open a terminal", err_text(res))
			return
		end
		local ok, doc = pcall(tern.json.decode, res.stdout)
		local pane = ok and type(doc) == "table" and (doc.block or doc.pane)
		if type(pane) == "number" then
			tern.kv.set("link:" .. link, pane)
		end
	end)
end

---------------------------------------------------------------------------------------------------
-- Sidebar

type SidebarState = {
	link: string,
	pane: number,
	machine: string,
	machines: { string },
	snap: common.Snapshot?,
	branches: { [string]: string },
	sel: number,
	split: number, -- share of the height the spaces section takes, 0.1 to 0.9
	menu: boolean,
	confirm: string?, -- a destructive menu item waiting for its second click
	integrations: { common.Integration }?, -- for the current machine
	ticks: number,
	closed: boolean,
}

local function agents(state: SidebarState): { common.Agent }
	return state.snap and state.snap.agents or {}
end

local function shown(state: SidebarState): (string?, string?)
	return common.link_target(state.link)
end

local function clamp(state: SidebarState)
	state.sel = math.clamp(state.sel, 1, math.max(1, #agents(state)))
end

local function select_terminal(state: SidebarState, terminal_id: string)
	for i, a in agents(state) do
		if a.terminal_id == terminal_id then
			state.sel = i
		end
	end
end

local function attach_agent(state: SidebarState, cx: EffectCx, a: common.Agent)
	show_terminal(cx, state.link, state.pane, a.machine, a.terminal_id)
end

local function attach_space(state: SidebarState, cx: EffectCx, workspace_id: string)
	local snap = state.snap
	if not snap then
		return
	end
	-- Agents come sorted by urgency, so the first one in the space is the one to see.
	for i, a in snap.agents do
		if a.workspace_id == workspace_id then
			state.sel = i
			attach_agent(state, cx, a)
			return
		end
	end
	local active
	for _, w in snap.workspaces do
		if w.id == workspace_id then
			active = w.active_tab
		end
	end
	local tabs = common.tabs_of(snap, workspace_id)
	local tab_id = active or (tabs[1] and tabs[1].id)
	local pane = tab_id and common.panes_of(snap, tab_id)[1]
	if pane then
		show_terminal(cx, state.link, state.pane, snap.machine, pane.terminal_id)
	end
end

-- The space the sidebar's terminal shows, else the focused one.
local function current_space(state: SidebarState): common.Workspace?
	local snap = state.snap
	if not snap then
		return nil
	end
	local machine, terminal = shown(state)
	local pane = machine == snap.machine and terminal and common.pane_by_terminal(snap, terminal)
	for _, w in snap.workspaces do
		if (pane and w.id == pane.workspace_id) or (not pane and w.focused) then
			return w
		end
	end
	return snap.workspaces[1]
end

local function space_cwd(state: SidebarState, w: common.Workspace?): string?
	local snap = state.snap
	if not snap or not w then
		return nil
	end
	for _, t in common.tabs_of(snap, w.id) do
		local p = common.panes_of(snap, t.id)[1]
		if p then
			return p.cwd
		end
	end
	return nil
end

local function refresh_branches(state: SidebarState, cx: BlockCx)
	local snap = state.snap
	if not snap then
		return
	end
	for _, w in snap.workspaces do
		local cwd = space_cwd(state, w)
		if cwd then
			local id, machine = w.id, snap.machine
			tern.process.run(common.shell_argv(machine, { "git", "-C", cwd, "branch", "--show-current" }), { timeout_ms = 5000 }, function(res)
				local branch = res.status == 0 and string.gsub(res.stdout, "%s+$", "") or ""
				if state.machine == machine and state.branches[id] ~= branch then
					state.branches[id] = branch
					pcall(cx.render, cx)
				end
			end)
		end
	end
end

local INTEGRATIONS_EVERY = 40 -- polls between integration checks (about a minute)

local function check_integrations(state: SidebarState, cx: BlockCx)
	local machine = state.machine
	common.integrations(machine, function(list)
		if state.machine == machine and list then
			state.integrations = list
			pcall(cx.render, cx)
		end
	end)
end

local function install(state: SidebarState, cx: BlockCx, name: string)
	local machine = state.machine
	cx:toast("info", "Installing the " .. name .. " integration" .. (machine ~= "local" and (" on " .. machine) or ""))
	tern.process.run(common.argv(machine, { "integration", "install", name }), { timeout_ms = 60000 }, function(res)
		local out = string.gsub(res.stderr .. res.stdout, "%s+$", "")
		if res.status == 0 then
			cx:toast("success", name .. " integration installed", out)
		else
			cx:toast("error", name .. " integration failed", out)
		end
		check_integrations(state, cx)
	end)
end

local function needs_integrations(state: SidebarState): boolean
	for _, i in state.integrations or {} do
		if common.needs_install(i) then
			return true
		end
	end
	return false
end

local function poll(state: SidebarState, cx: BlockCx, again: boolean)
	if state.closed then
		return
	end
	if not alive(state.pane) then
		state.closed = true
		return
	end
	local machine = state.machine
	common.snapshot(machine, function(snap)
		if state.closed then
			return
		end
		if state.machine == machine then
			local current = agents(state)[state.sel]
			state.snap = snap
			if current then
				select_terminal(state, current.terminal_id)
			end
			clamp(state)
			if state.ticks % BRANCH_EVERY == 0 then
				refresh_branches(state, cx)
			end
			if state.ticks % INTEGRATIONS_EVERY == 0 then
				check_integrations(state, cx)
			end
			state.ticks += 1
			if not pcall(cx.render, cx) then
				state.closed = true
				return
			end
		end
		if again then
			tern.timer(POLL_MS, function()
				poll(state, cx, true)
			end)
		end
	end)
end

local function switch_machine(state: SidebarState, cx: BlockCx, machine: string)
	if state.machine == machine then
		return
	end
	state.machine = machine
	state.snap = nil
	state.integrations = nil
	state.branches = {}
	state.sel = 1
	state.ticks = 0
	poll(state, cx, false)
	cx:save()
end

-- Menu and bar actions. Destructive ones need a second click.
local function act(state: SidebarState, cx: BlockCx, name: string, value: string?)
	local machine = state.machine
	local w = current_space(state)
	if name == "new_space" then
		local args = { "workspace", "create", "--no-focus" }
		local cwd = space_cwd(state, w)
		if cwd then
			table.insert(args, "--cwd")
			table.insert(args, cwd)
		end
		herdr(cx, machine, args, function(r)
			if r.root_pane and r.root_pane.terminal_id then
				show_terminal(cx, state.link, state.pane, machine, r.root_pane.terminal_id)
			end
			poll(state, cx, false)
		end)
	elseif name == "new_tab" and w then
		local args = { "tab", "create", "--workspace", w.id, "--no-focus" }
		local cwd = space_cwd(state, w)
		if cwd then
			table.insert(args, "--cwd")
			table.insert(args, cwd)
		end
		herdr(cx, machine, args, function(r)
			if r.root_pane and r.root_pane.terminal_id then
				show_terminal(cx, state.link, state.pane, machine, r.root_pane.terminal_id)
			end
			poll(state, cx, false)
		end)
	elseif name == "close_space" and w then
		if state.confirm ~= "close_space" then
			state.confirm = "close_space"
			return
		end
		herdr(cx, machine, { "workspace", "close", w.id }, function()
			poll(state, cx, false)
		end)
	elseif name == "machine" and value then
		switch_machine(state, cx, value)
	elseif name == "install" and value then
		install(state, cx, value)
	elseif name == "mirror" then
		if tern.kv.get("mirror") ~= nil then
			tern.kv.set("mirror_stop", true)
		else
			tern.kv.set("mirror", {})
		end
	elseif name == "refresh" then
		state.ticks = 0
		poll(state, cx, false)
	elseif name == "up" then
		state.split = math.max(0.1, state.split - 0.1)
		cx:save()
	elseif name == "down" then
		state.split = math.min(0.9, state.split + 0.1)
		cx:save()
	end
	state.confirm = nil
	state.menu = false
end

local function space_rows(state: SidebarState): { Node }
	local snap = state.snap :: common.Snapshot
	local machine, terminal = shown(state)
	local rows = {}
	for _, w in snap.workspaces do
		local on = false
		if machine == snap.machine and terminal then
			local p = common.pane_by_terminal(snap, terminal)
			on = p ~= nil and p.workspace_id == w.id
		end
		local children = { el("div", "hs-line", nil, { dot(w.status), el("span", "hs-name", w.label) }) }
		local branch = state.branches[w.id]
		if branch and branch ~= "" then
			table.insert(children, el("div", "hs-sub", branch))
		end
		table.insert(rows, el("div", "hs-row" .. (on and " hs-on" or ""), nil, children, "space=" .. w.id))
		if on then
			-- The shown space's Herdr tabs, "1 2 +", one line under it.
			local p = common.pane_by_terminal(snap, terminal :: string)
			local chips = {}
			for _, t in common.tabs_of(snap, w.id) do
				table.insert(chips, el("span", "hs-tab" .. (p and t.id == p.tab_id and " hs-tab-on" or ""), nil, {
					dot(t.status),
					el("span", "", t.label),
				}, "tab=" .. t.id))
			end
			table.insert(chips, el("span", "hs-tab hs-tab-new", "+", nil, "new_tab"))
			table.insert(rows, el("div", "hs-tabs", nil, chips))
		end
	end
	return rows
end

local function agent_rows(state: SidebarState): { Node }
	local snap = state.snap :: common.Snapshot
	local labels, seen, totals = {}, {}, {}
	for _, w in snap.workspaces do
		labels[w.id] = w.label
	end
	for _, a in snap.agents do
		totals[a.workspace_id] = (totals[a.workspace_id] or 0) + 1
	end
	local machine, terminal = shown(state)
	local rows = {}
	for i, a in snap.agents do
		seen[a.workspace_id] = (seen[a.workspace_id] or 0) + 1
		local line = { dot(a.status), el("span", "hs-name", labels[a.workspace_id] or common.basename(a.cwd)) }
		if totals[a.workspace_id] > 1 then
			table.insert(line, el("span", "hs-n", "· " .. seen[a.workspace_id]))
		end
		local class = "hs-row hs-agent"
		if machine == a.machine and terminal == a.terminal_id then
			class ..= " hs-on"
		end
		if i == state.sel then
			class ..= " hs-sel"
		end
		local row = el("div", class, nil, {
			el("div", "hs-line", nil, line),
			el("div", "hs-sub", a.agent .. (a.title ~= "" and (" · " .. a.title) or "")),
		}, "pick=" .. a.terminal_id)
		local p = row.p :: { [string]: any }
		p.title = common.label(a) .. " (" .. a.status .. ")"
		table.insert(rows, row)
	end
	return rows
end

local function menu_view(state: SidebarState): Node
	local w = current_space(state)
	local items: { Node } = {}
	local function item(label: string, click: string, class: string?)
		table.insert(items, el("div", "hs-mi" .. (class and (" " .. class) or ""), label, nil, click))
	end
	item("New space", "new_space")
	if w then
		item("New tab in " .. w.label, "new_tab")
		if state.confirm == "close_space" then
			item("Click again to close " .. w.label, "close_space", "hs-danger")
		else
			item("Close space " .. w.label .. "…", "close_space")
		end
	end
	table.insert(items, el("div", "hs-msep", ""))
	if state.integrations then
		local installed = 0
		for _, i in state.integrations do
			if common.needs_install(i) then
				local verb = i.state == "outdated" and "Update" or "Install"
				item("● " .. verb .. " " .. i.name .. " integration", "install=" .. i.name, "hs-attn")
			elseif i.state == "current" then
				installed += 1
			end
		end
		table.insert(items, el("div", "hs-mnote", installed .. " integrations installed" .. (state.machine ~= "local" and (" on " .. state.machine) or "")))
		table.insert(items, el("div", "hs-msep", ""))
	end
	if #state.machines > 1 then
		for _, m in state.machines do
			item((m == state.machine and "● " or "○ ") .. m, "machine=" .. m)
		end
		table.insert(items, el("div", "hs-msep", ""))
	end
	item(tern.kv.get("mirror") ~= nil and "Close Tern tabs (mirror off)" or "Open as Tern tabs (mirror on)", "mirror")
	item("Refresh", "refresh")
	item("Close menu", "menu")
	return el("div", "hs-menu", nil, items)
end

local sidebar: BlockDef<SidebarState> = {
	init = function(cx, args, saved)
		local link = args[1] or (saved and saved.link) or common.new_link()
		local machines = common.machines()
		local machine = args[2] or (saved and saved.machine) or "local"
		if not table.find(machines, machine) then
			machine = "local"
		end
		local state: SidebarState = {
			link = link,
			pane = cx.pane,
			machine = machine,
			machines = machines,
			snap = nil,
			branches = {},
			sel = 1,
			split = saved and saved.split or 0.5,
			menu = false,
			confirm = nil,
			integrations = nil,
			ticks = 0,
			closed = false,
		}
		-- The window finds the sidebar's link (and through it, its terminal) by pane id.
		local links = tern.kv.get("links") or {}
		links[tostring(cx.pane)] = link
		tern.kv.set("links", links)
		poll(state, cx, true)
		return state
	end,

	save = function(state)
		return { link = state.link, machine = state.machine, split = state.split }
	end,

	title = function(state)
		local c = common.counts(agents(state))
		local name = state.machine == "local" and "herdr" or ("herdr · " .. state.machine)
		if c.blocked then
			return name .. " · " .. c.blocked .. " blocked"
		end
		return name
	end,

	view = function(state, _cx)
		local body: { Node } = {}
		if #state.machines > 1 then
			local chips = {}
			for _, m in state.machines do
				table.insert(chips, el("span", "hs-chip" .. (m == state.machine and " hs-chip-on" or ""), m, nil, "machine=" .. m))
			end
			table.insert(body, el("div", "hs-machines", nil, chips))
		end
		local snap = state.snap
		if not snap then
			table.insert(body, el("div", "hs-sub", "loading " .. state.machine .. "…"))
		elseif snap.err then
			table.insert(body, el("div", "hs-err", "Herdr on " .. state.machine .. " is not reachable"))
			table.insert(body, el("div", "hs-sub", snap.err))
		else
			local spaces = { el("div", "hs-head", "spaces") }
			for _, r in space_rows(state) do
				table.insert(spaces, r)
			end
			local pct = math.floor(state.split * 10 + 0.5) * 10
			table.insert(body, el("div", "hs-spaces hs-h" .. pct, nil, spaces))
			table.insert(body, el("div", "hs-bar", nil, {
				el("span", "hs-btn", "new", nil, "new_space"),
				el("span", "hs-grow", ""),
				el("span", "hs-btn hs-arrow", "▴", nil, "up"),
				el("span", "hs-btn hs-arrow", "▾", nil, "down"),
				el("span", "hs-grow", ""),
				el("span", "hs-btn hs-menu-btn" .. (needs_integrations(state) and " hs-attn" or ""), "menu", nil, "menu"),
			}))
			if state.menu then
				-- The block's layer region doesn't draw here, so the menu opens inline under the bar.
				table.insert(body, menu_view(state))
			end
			local list = { el("div", "hs-head", nil, { el("span", "", "agents"), el("span", "hs-right", "priority") }) }
			if #snap.agents == 0 then
				table.insert(list, el("div", "hs-sub", "no agents"))
			end
			for _, r in agent_rows(state) do
				table.insert(list, r)
			end
			table.insert(body, el("div", "hs-agents", nil, list))
		end
		return { main = ui.col({ el("div", "hs", nil, body) }) }
	end,

	key = function(state, key, cx)
		local name = key.name
		if state.menu then
			if name == "escape" then
				state.menu = false
				state.confirm = nil
				return true
			end
			return false
		end
		if name == "down" or name == "j" then
			state.sel += 1
		elseif name == "up" or name == "k" then
			state.sel -= 1
		elseif name == "[" then
			act(state, cx, "up")
		elseif name == "]" then
			act(state, cx, "down")
		elseif name == "m" then
			state.menu = true
		elseif name == "n" then
			act(state, cx, "new_space")
		elseif name == "r" then
			act(state, cx, "refresh")
			return false
		elseif name == "enter" or name == "space" then
			local a = agents(state)[state.sel]
			if a then
				attach_agent(state, cx, a)
			end
		else
			return false
		end
		clamp(state)
		return true
	end,

	event = function(state, ev, cx)
		if ev.ev ~= "action" then
			return
		end
		local name, value = ev.act, ev.value
		if name == "pick" and value then
			select_terminal(state, value)
			local a = agents(state)[state.sel]
			if a and a.terminal_id == value then
				attach_agent(state, cx, a)
			end
		elseif name == "space" and value then
			attach_space(state, cx, value)
		elseif name == "tab" and value and state.snap then
			local p = common.panes_of(state.snap, value)[1]
			if p then
				show_terminal(cx, state.link, state.pane, state.snap.machine, p.terminal_id)
			end
		elseif name == "menu" then
			state.menu = not state.menu
			state.confirm = nil
		else
			act(state, cx, name, value)
		end
	end,
}

tern.block.define("sidebar", sidebar)

---------------------------------------------------------------------------------------------------
-- Tab strip: the shown space's Herdr tabs ("1 2 +") above the sidebar's terminal.

type StripState = {
	link: string,
	pane: number,
	snap: common.Snapshot?,
	closed: boolean,
}

-- The machine and Herdr pane the link's terminal shows.
local function strip_place(state: StripState): (string?, common.Pane?)
	local machine, terminal = common.link_target(state.link)
	local snap = state.snap
	if not machine or not terminal or not snap or snap.machine ~= machine then
		return machine, nil
	end
	return machine, common.pane_by_terminal(snap, terminal)
end

local function strip_poll(state: StripState, cx: BlockCx)
	if state.closed or not alive(state.pane) then
		state.closed = true
		return
	end
	local machine = common.link_target(state.link) or "local"
	common.snapshot(machine, function(snap)
		state.snap = snap
		if not pcall(cx.render, cx) then
			state.closed = true
			return
		end
		tern.timer(POLL_MS, function()
			strip_poll(state, cx)
		end)
	end)
end

local strip: BlockDef<StripState> = {
	init = function(cx, args, saved)
		local state: StripState = {
			link = args[1] or (saved and saved.link) or "",
			pane = cx.pane,
			snap = nil,
			closed = false,
		}
		strip_poll(state, cx)
		return state
	end,

	save = function(state)
		return { link = state.link }
	end,

	title = function(_state)
		return "herdr tabs"
	end,

	view = function(state, _cx)
		local machine, pane = strip_place(state)
		local chips: { Node } = {}
		if pane and state.snap then
			for _, t in common.tabs_of(state.snap, pane.workspace_id) do
				local on = t.id == pane.tab_id
				table.insert(chips, el("span", "ht-tab" .. (on and " ht-on" or ""), nil, {
					dot(t.status),
					el("span", "", t.label),
				}, "tab=" .. t.id))
			end
			table.insert(chips, el("span", "ht-tab ht-new", "+", nil, "new"))
			if machine and machine ~= "local" then
				table.insert(chips, el("span", "hs-grow", ""))
				table.insert(chips, el("span", "ht-machine", machine))
			end
		end
		return { main = ui.col({ el("div", "ht", nil, chips) }) }
	end,

	event = function(state, ev, cx)
		if ev.ev ~= "action" then
			return
		end
		local machine, pane = strip_place(state)
		local snap = state.snap
		if not machine or not pane or not snap then
			return
		end
		if ev.act == "tab" and ev.value then
			local target = common.panes_of(snap, ev.value)[1]
			if target then
				common.retarget(state.link, linked_term(state.link), machine, target.terminal_id, tern.pane.write)
			end
		elseif ev.act == "new" then
			herdr(cx, machine, { "tab", "create", "--workspace", pane.workspace_id, "--cwd", pane.cwd, "--no-focus" }, function(r)
				if r.root_pane and r.root_pane.terminal_id then
					common.retarget(state.link, linked_term(state.link), machine, r.root_pane.terminal_id, tern.pane.write)
				end
			end)
		end
	end,
}

tern.block.define("tabs", strip)
