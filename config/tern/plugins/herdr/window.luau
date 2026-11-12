-- Window half: polls Herdr on each machine, mirrors its tabs and panes as Tern tabs and splits,
-- maps Herdr's prefix keys onto Herdr API calls, and adds toasts, a status segment and the sidebar.

local common = require("./common")
local keymap = require("./keymap")

local POLL_MS = 2000
local SIDEBAR_RATIO = 0.17

type Snapshot = common.Snapshot
type Pane = common.Pane
type Tab = common.Tab
type Workspace = common.Workspace

local machines = common.machines()
local snaps: { [string]: Snapshot } = {} -- latest snapshot per machine
local last: { [string]: string }? = nil -- "machine|pane" -> agent status from the previous poll
local summary = "" -- counts string; a change refreshes the chrome

local function all_agents(): { common.Agent }
	local out = {}
	for _, m in machines do
		local snap = snaps[m]
		if snap then
			for _, a in snap.agents do
				table.insert(out, a)
			end
		end
	end
	common.sort(out)
	return out
end

local function pane_by_key(key: string): Pane?
	local machine, id = string.match(key, "^(.-)|(.+)$")
	local snap = machine and snaps[machine]
	return snap and snap.panes[id] or nil
end

local function workspace_of(snap: Snapshot, id: string): Workspace?
	for _, w in snap.workspaces do
		if w.id == id then
			return w
		end
	end
	return nil
end

---------------------------------------------------------------------------------------------------
-- Toasts and status

local function urgent(): common.Agent?
	for _, a in all_agents() do
		if a.status == "blocked" or a.status == "done" then
			return a
		end
	end
	return nil
end

local function notify(cx: WindowCx, a: common.Agent, before: string?)
	if before == a.status then
		return
	end
	local where = common.basename(a.cwd) .. (a.machine ~= "local" and (" on " .. a.machine) or "")
	if a.status == "blocked" then
		cx:toast("error", a.agent .. " needs input · " .. where, common.label(a))
	elseif a.status == "done" and before == "working" then
		cx:toast("success", a.agent .. " finished · " .. where, common.label(a))
	end
end

local function after_poll(cx: WindowCx?)
	local agents = all_agents()
	local now = {}
	for _, a in agents do
		local key = a.machine .. "|" .. a.pane_id
		now[key] = a.status
		-- The first poll only records states; toasts start from the second.
		if last and cx then
			notify(cx, a, last[key])
		end
	end
	last = now
	local c = common.counts(agents)
	local key = string.format("%d/%d/%d/%d", c.blocked or 0, c.working or 0, c.done or 0, c.idle or 0)
	if key ~= summary then
		summary = key
		tern.chrome.refresh()
	end
end

tern.chrome.status(function(_pane)
	local agents = all_agents()
	if #agents == 0 then
		return nil
	end
	local c = common.counts(agents)
	local parts = {}
	for _, s in common.STATES do
		if c[s] and s ~= "idle" then
			table.insert(parts, c[s] .. " " .. s)
		end
	end
	if #parts == 0 then
		table.insert(parts, #agents .. " idle")
	end
	local tone = (c.blocked and "error") or (c.working and "warn") or "muted"
	return { { text = "herdr " .. table.concat(parts, " · "), icon = "user", tone = tone, command = "plugin.herdr.open" } }
end)

tern.carly.context(function(_cx)
	local agents = all_agents()
	if #agents == 0 then
		return nil
	end
	local lines = {}
	for _, a in agents do
		table.insert(lines, string.format("%s:%s %s %s (%s)", a.machine, a.pane_id, a.agent, a.status, common.label(a)))
		if #lines >= 8 then
			break
		end
	end
	return "Herdr agents:\n" .. table.concat(lines, "\n")
end)

---------------------------------------------------------------------------------------------------
-- Sidebar tab: the native sidebar and one terminal that follows the picked pane.

-- The sidebar tab open in this window: its link id, sidebar pane and terminal pane.
local function sidebar_link(cx: WindowCx): (string?, number?, number?)
	for _, p in cx.session:panes() do
		if p.block == "herdr.sidebar" then
			local link = (tern.kv.get("links") or {})[tostring(p.pane)]
			if link then
				local term = tern.kv.get("link:" .. link)
				if type(term) == "number" and cx.session:pane(term) == nil then
					term = nil
				end
				return link, p.pane, term
			end
		end
	end
	return nil, nil, nil
end

local function open_sidebar(cx: WindowCx, machine: string?, terminal_id: string?)
	local link, sidebar, term = sidebar_link(cx)
	if link and sidebar then
		if machine and terminal_id then
			common.retarget(link, term, machine, terminal_id, function(pane, text)
				cx:run(pane, text)
			end)
		end
		cx.layout:focus(term or sidebar)
		return
	end
	link = common.new_link()
	if not (machine and terminal_id) then
		local a = all_agents()[1]
		if a then
			machine, terminal_id = a.machine, a.terminal_id
		end
	end
	if machine and terminal_id then
		tern.fs.write(common.target_file(link), common.encode_target(machine, terminal_id))
	end
	local tab, err = cx.layout:tab({
		name = "herdr",
		split = "right",
		ratio = SIDEBAR_RATIO,
		{ launch = { block = "herdr.sidebar", args = { link, machine or "local" } } },
		{ launch = { command = common.follow_command(link) } },
	})
	if not tab then
		cx:toast("error", "Could not open the Herdr tab", err)
		return
	end
	local layout = cx.session:layout(tab)
	local right = layout and layout.root and layout.root[2]
	local terminal = right and right.pane
	if terminal then
		tern.kv.set("link:" .. link, terminal)
		cx.layout:focus(terminal)
	end
end

---------------------------------------------------------------------------------------------------
-- Mirror: each Herdr tab is a Tern tab and each Herdr pane a Tern split attached to it.
-- kv "mirror" maps "machine|pane" to the Tern pane attached to it; absent means off.

local TAB_COLOR: { [string]: TabColor } = { blocked = "red", working = "yellow", done = "green" }
local applied: { [number]: string } = {} -- Tern tab -> name this plugin last set
local renamed: { [number]: boolean } = {} -- Tern tabs the user renamed; their names stay
local colors: { [number]: string } = {} -- Tern tab -> color this plugin last set
local dismissed: { [string]: boolean } = {} -- Herdr panes whose Tern pane the user closed
local pending_dir: { [string]: Dir } = {} -- new Herdr pane key -> split direction asked for
local pending_focus: string? = nil -- Herdr pane key to focus once it is mirrored

local function mirror_on(): boolean
	return tern.kv.get("mirror") ~= nil
end

local function mirror_map(): { [string]: number }
	return tern.kv.get("mirror") or {}
end

local function pane_link(key: string): string
	return "m-" .. string.gsub(key, "[^%w]", "_")
end

local function tab_name(snap: Snapshot, t: Tab): string
	local w = workspace_of(snap, t.workspace_id)
	local name = w and w.label or t.workspace_id
	if #common.tabs_of(snap, t.workspace_id) > 1 then
		name ..= " · " .. t.label
	end
	if snap.machine ~= "local" then
		name = snap.machine .. ": " .. name
	end
	return name
end

local function tern_tab_info(cx: WindowCx, tab: number): TabInfo?
	for _, info in cx.session:tabs() do
		if info.id == tab then
			return info
		end
	end
	return nil
end

local function sync_mirror(cx: WindowCx)
	if not mirror_on() then
		return
	end
	local map = mirror_map()
	local prev_tab: number? = nil -- the Tern tab of the previous Herdr tab, for ordering
	local was_focused = cx.session:focused()
	local created = false

	for _, machine in machines do
		local snap = snaps[machine]
		if snap and not snap.err then
			for _, t in snap.tabs do
				local anchor: number? = nil
				for _, p in common.panes_of(snap, t.id) do
					local term = map[p.key]
					if term and cx.session:pane(term) == nil then
						-- The user closed it in Tern: leave it hidden; Herdr keeps the pane.
						map[p.key] = nil
						dismissed[p.key] = true
						term = nil
					end
					if term then
						anchor = anchor or term
					end
				end
				for _, p in common.panes_of(snap, t.id) do
					if not map[p.key] and not dismissed[p.key] and p.terminal_id ~= "" then
						local link = pane_link(p.key)
						tern.fs.write(common.target_file(link), common.encode_target(machine, p.terminal_id))
						local launch = { command = common.follow_command(link) }
						if machine == "local" then
							launch.cwd = p.cwd
						end
						local term
						if anchor then
							term = cx.layout:split(anchor, pending_dir[p.key] or "right", launch, { focus = false })
						else
							term = cx.layout:new_tab(launch, { focus = false })
							local tab = term and cx.session:tab_of(term)
							local after = prev_tab and tern_tab_info(cx, prev_tab)
							if tab and after then
								cx.layout:order_tab(tab, after.position + 1)
							end
						end
						pending_dir[p.key] = nil
						if term then
							created = true
							map[p.key] = term
							anchor = anchor or term
						end
					end
				end
				local tab = anchor and cx.session:tab_of(anchor)
				if tab then
					prev_tab = tab
					local info = tern_tab_info(cx, tab)
					-- A name this plugin didn't set means the user renamed the tab; keep theirs.
					if info and applied[tab] and info.name ~= applied[tab] then
						renamed[tab] = true
					end
					local name = tab_name(snap, t)
					if not renamed[tab] and applied[tab] ~= name then
						applied[tab] = name
						cx.layout:name_tab(tab, name)
					end
					local color = TAB_COLOR[t.status]
					if colors[tab] ~= (color or "") then
						colors[tab] = color or ""
						cx.layout:color_tab(tab, color)
					end
				end
			end
		end
	end

	-- Panes that left Herdr take their Tern panes with them. An unreachable machine keeps its tabs.
	for key, term in map do
		local machine = string.match(key, "^(.-)|")
		local snap = machine and snaps[machine]
		if snap and not snap.err and not pane_by_key(key) then
			if cx.session:pane(term) then
				cx.layout:close(term)
			end
			map[key] = nil
		end
	end
	for key in dismissed do
		if not pane_by_key(key) then
			dismissed[key] = nil
		end
	end
	tern.kv.set("mirror", map)

	if pending_focus and map[pending_focus] then
		cx.layout:focus(map[pending_focus])
		pending_focus = nil
	elseif created and was_focused and cx.session:pane(was_focused) then
		-- New tabs reveal themselves; put the user back where they were.
		cx.layout:focus(was_focused)
	end
end

local function stop_mirror(cx: WindowCx)
	for _, term in mirror_map() do
		if cx.session:pane(term) then
			cx.layout:close(term)
		end
	end
	tern.kv.set("mirror", nil)
	tern.kv.set("mirror_stop", nil)
	applied, renamed, colors, dismissed = {}, {}, {}, {}
end

---------------------------------------------------------------------------------------------------
-- Polling

-- Snapshots every machine, then runs `done` once with the last callback's cx.
local function snapshot_all(done: (WindowCx?) -> ())
	local pending = #machines
	local cx_seen: WindowCx? = nil
	for i, machine in machines do
		-- One timer per machine: spawning every machine's processes in one callback can pass
		-- the window's 50 ms budget.
		tern.timer((i - 1) * 60, function()
			common.snapshot(machine, function(snap, cx)
				snaps[machine] = snap
				cx_seen = cx or cx_seen
				pending -= 1
				if pending == 0 then
					done(cx_seen)
				end
			end)
		end)
	end
end

local function settle(cx: WindowCx?)
	if not cx then
		return
	end
	-- The sidebar menu asks for the mirror through kv.
	if tern.kv.get("mirror_stop") then
		stop_mirror(cx)
	end
	sync_mirror(cx)
end

local function poll()
	snapshot_all(function(cx)
		after_poll(cx)
		settle(cx)
		tern.timer(POLL_MS, function()
			poll()
		end)
	end)
end

-- Refreshes now (after a Herdr change), then syncs.
local function refresh_now()
	snapshot_all(settle)
end

---------------------------------------------------------------------------------------------------
-- Prefix keys: Herdr's keymap, run against the Herdr pane shown in the focused Tern pane.

-- The Herdr pane behind the focused Tern pane: a mirrored pane, or the sidebar tab's terminal.
local function current(cx: WindowCx): Pane?
	local focused = cx.session:focused()
	if not focused then
		return nil
	end
	for key, term in mirror_map() do
		if term == focused then
			return pane_by_key(key)
		end
	end
	local link, sidebar, term = sidebar_link(cx)
	if link and (focused == sidebar or focused == term) then
		local machine, terminal = common.link_target(link)
		local snap = machine and snaps[machine]
		return snap and terminal and common.pane_by_terminal(snap, terminal) or nil
	end
	return nil
end

-- Shows a Herdr pane: its mirrored Tern pane, else the sidebar terminal.
local function show(cx: WindowCx, p: Pane)
	local term = mirror_on() and mirror_map()[p.key]
	if term and cx.session:pane(term) then
		cx.layout:focus(term)
	elseif mirror_on() then
		pending_focus = p.key
		dismissed[p.key] = nil
		refresh_now()
	else
		open_sidebar(cx, p.machine, p.terminal_id)
	end
end

local function herdr(cx: WindowCx, machine: string, args: { string }, done: ((any) -> ())?)
	tern.process.run(common.argv(machine, args), { timeout_ms = 10000 }, function(res, cx2)
		local c = cx2 or cx
		local ok, doc = pcall(tern.json.decode, res.stdout)
		if res.status ~= 0 or not ok or type(doc) ~= "table" or doc.error then
			local msg = ok and type(doc) == "table" and doc.error and doc.error.message or (res.stderr .. res.stdout)
			c:toast("error", "herdr " .. args[1] .. " " .. (args[2] or "") .. " failed", tostring(msg))
			return
		end
		if done then
			done(doc.result)
		end
		refresh_now()
	end)
end

-- Opens a newly created Herdr pane once it is mirrored (or in the sidebar terminal).
local function reveal_new(cx: WindowCx, machine: string, pane: any, dir: Dir?)
	if type(pane) ~= "table" or not pane.pane_id then
		return
	end
	local key = machine .. "|" .. pane.pane_id
	if dir then
		pending_dir[key] = dir
	end
	if mirror_on() then
		pending_focus = key
	elseif pane.terminal_id then
		open_sidebar(cx, machine, pane.terminal_id)
	end
end

local function step(list: { any }, index: number, by: number): any
	if #list == 0 then
		return nil
	end
	return list[((index - 1 + by) % #list) + 1]
end

local function index_of(list: { any }, pred: (any) -> boolean): number
	for i, v in list do
		if pred(v) then
			return i
		end
	end
	return 1
end

local function tab_pane(snap: Snapshot?, t: Tab?): Pane?
	return snap and t and common.panes_of(snap, t.id)[1] or nil
end

local function workspace_pane(snap: Snapshot?, w: Workspace?): Pane?
	if not snap or not w then
		return nil
	end
	local tabs = common.tabs_of(snap, w.id)
	for _, t in tabs do
		if t.id == w.active_tab then
			return tab_pane(snap, t)
		end
	end
	return tab_pane(snap, tabs[1])
end

-- Agents of one machine in space order, as Herdr's next/previous agent cycles them.
local function agents_by_space(snap: Snapshot): { common.Agent }
	local order = {}
	for i, w in snap.workspaces do
		order[w.id] = i
	end
	local list = table.clone(snap.agents)
	table.sort(list, function(a, b)
		local oa, ob = order[a.workspace_id] or 999, order[b.workspace_id] or 999
		if oa ~= ob then
			return oa < ob
		end
		return a.pane_id < b.pane_id
	end)
	return list
end

-- Focuses the neighbouring Tern pane in `dir` within the focused pane's tab.
local function focus_dir(cx: WindowCx, dir: Dir)
	local focused = cx.session:focused()
	local tab = focused and cx.session:tab_of(focused)
	local layout = tab and cx.session:layout(tab)
	if not layout or not focused then
		return
	end
	local axis = (dir == "left" or dir == "right") and "right" or "down"
	local forward = dir == "right" or dir == "down"
	local path = {}
	local function find(node: TabTree): boolean
		if node.pane == focused then
			return true
		end
		for side = 1, 2 do
			local child = node[side]
			if child then
				table.insert(path, { node = node, side = side })
				if find(child) then
					return true
				end
				table.remove(path)
			end
		end
		return false
	end
	if not find(layout.root) then
		return
	end
	for i = #path, 1, -1 do
		local hop = path[i]
		if hop.node.split == axis and hop.side == (forward and 1 or 2) then
			local node = hop.node[forward and 2 or 1]
			-- Descend to the leaf nearest the edge we came from.
			while node and not node.pane do
				node = node[(node.split == axis and not forward) and 2 or 1]
			end
			if node and node.pane then
				cx.layout:focus(node.pane)
			end
			return
		end
	end
end

local recent_focus: { number } = {} -- the two most recently focused Tern panes

tern.on("focus", function(ev: FocusEvent, _cx)
	if recent_focus[1] ~= ev.pane then
		table.insert(recent_focus, 1, ev.pane)
		recent_focus[3] = nil
	end
end)

local function within(cx: WindowCx, p: Pane?, list_of: (Snapshot, Pane) -> { any }, match: (any, Pane) -> boolean, by: number, pane_of: (Snapshot, any) -> Pane?)
	local snap = p and snaps[p.machine]
	if not p or not snap then
		return
	end
	local list = list_of(snap, p)
	local target = pane_of(snap, step(list, index_of(list, function(v)
		return match(v, p)
	end), by))
	if target then
		show(cx, target)
	end
end

local function space_tabs(snap: Snapshot, p: Pane): { any }
	return common.tabs_of(snap, p.workspace_id)
end
local function same_tab(t: any, p: Pane): boolean
	return t.id == p.tab_id
end
local function spaces(snap: Snapshot, _p: Pane): { any }
	return snap.workspaces
end
local function same_space(w: any, p: Pane): boolean
	return w.id == p.workspace_id
end
local function agent_list(snap: Snapshot, _p: Pane): { any }
	return agents_by_space(snap)
end
local function same_agent(a: any, p: Pane): boolean
	return a.pane_id == p.id
end
local function agent_pane(snap: Snapshot, a: any): Pane?
	return a and snap.panes[a.pane_id] or nil
end

-- Handlers by Herdr action name. `n` is the 1-based index of indexed bindings.
local ACTIONS: { [string]: (cx: WindowCx, p: Pane?, n: number?) -> () } = {
	new_tab = function(cx, p)
		if p then
			herdr(cx, p.machine, { "tab", "create", "--no-focus", "--workspace", p.workspace_id, "--cwd", p.cwd }, function(r)
				reveal_new(cx, p.machine, r.root_pane)
			end)
		end
	end,
	new_workspace = function(cx, p)
		local machine = p and p.machine or "local"
		local args = { "workspace", "create", "--no-focus" }
		if p then
			table.insert(args, "--cwd")
			table.insert(args, p.cwd)
		end
		herdr(cx, machine, args, function(r)
			reveal_new(cx, machine, r.root_pane)
		end)
	end,
	split_vertical = function(cx, p)
		if p then
			herdr(cx, p.machine, { "pane", "split", p.id, "--direction", "right", "--cwd", p.cwd, "--no-focus" }, function(r)
				reveal_new(cx, p.machine, r.pane, "right")
			end)
		end
	end,
	split_horizontal = function(cx, p)
		if p then
			herdr(cx, p.machine, { "pane", "split", p.id, "--direction", "down", "--cwd", p.cwd, "--no-focus" }, function(r)
				reveal_new(cx, p.machine, r.pane, "down")
			end)
		end
	end,
	close_pane = function(cx, p)
		if p then
			herdr(cx, p.machine, { "pane", "close", p.id })
		end
	end,
	close_tab = function(cx, p)
		if p then
			herdr(cx, p.machine, { "tab", "close", p.tab_id })
		end
	end,
	close_workspace = function(cx, p)
		if p then
			herdr(cx, p.machine, { "workspace", "close", p.workspace_id })
		end
	end,
	next_tab = function(cx, p)
		within(cx, p, space_tabs, same_tab, 1, tab_pane)
	end,
	previous_tab = function(cx, p)
		within(cx, p, space_tabs, same_tab, -1, tab_pane)
	end,
	switch_tab = function(cx, p, n)
		local snap = p and snaps[p.machine]
		local target = snap and p and n and tab_pane(snap, common.tabs_of(snap, p.workspace_id)[n])
		if target then
			show(cx, target)
		end
	end,
	next_workspace = function(cx, p)
		within(cx, p, spaces, same_space, 1, workspace_pane)
	end,
	previous_workspace = function(cx, p)
		within(cx, p, spaces, same_space, -1, workspace_pane)
	end,
	switch_workspace = function(cx, p, n)
		local snap = snaps[p and p.machine or "local"]
		local target = snap and n and workspace_pane(snap, snap.workspaces[n])
		if target then
			show(cx, target)
		end
	end,
	next_agent = function(cx, p)
		within(cx, p, agent_list, same_agent, 1, agent_pane)
	end,
	previous_agent = function(cx, p)
		within(cx, p, agent_list, same_agent, -1, agent_pane)
	end,
	focus_pane_left = function(cx)
		focus_dir(cx, "left")
	end,
	focus_pane_down = function(cx)
		focus_dir(cx, "down")
	end,
	focus_pane_up = function(cx)
		focus_dir(cx, "up")
	end,
	focus_pane_right = function(cx)
		focus_dir(cx, "right")
	end,
	cycle_pane_next = function(cx)
		cx:action("next_pane")
	end,
	cycle_pane_previous = function(cx)
		cx:action("previous_pane")
	end,
	last_pane = function(cx)
		local prev = recent_focus[2]
		if prev and cx.session:pane(prev) then
			cx.layout:focus(prev)
		end
	end,
	zoom = function(cx)
		cx:action("zoom")
	end,
	rename_tab = function(cx)
		cx:action("rename_tab")
	end,
	workspace_picker = function(cx, p)
		open_sidebar(cx, p and p.machine, p and p.terminal_id)
	end,
	goto = function(cx, p)
		open_sidebar(cx, p and p.machine, p and p.terminal_id)
	end,
	toggle_sidebar = function(cx, p)
		open_sidebar(cx, p and p.machine, p and p.terminal_id)
	end,
	detach = function(cx)
		stop_mirror(cx)
	end,
}

local function in_herdr(cx: WindowCx): boolean
	return current(cx) ~= nil
end

local bound = keymap.load(common.herdr_config())
for _, b in bound.bindings do
	local handler = ACTIONS[b.action]
	if handler then
		tern.command({
			id = "key_" .. b.action .. (b.n and ("_" .. b.n) or ""),
			title = "Herdr: " .. keymap.title(b.action) .. (b.n and (" " .. b.n) or ""),
			group = "Herdr keys",
			keys = b.keys,
			available = in_herdr,
			run = function(cx)
				handler(cx, current(cx), b.n)
			end,
		})
	end
end

-- Prefix twice sends the prefix itself to the program, as in tmux.
tern.command({
	id = "key_send_prefix",
	title = "Herdr: Send Prefix",
	group = "Herdr keys",
	keys = { bound.prefix .. ">" .. bound.prefix },
	available = in_herdr,
	run = function(cx)
		local focused = cx.session:focused()
		if focused and bound.prefix_byte then
			cx:run(focused, bound.prefix_byte)
		end
	end,
})

---------------------------------------------------------------------------------------------------
-- Palette commands

tern.command({
	id = "open",
	title = "Herdr: Open Sidebar",
	icon = "user",
	keys = { "cmd+shift+h" },
	run = function(cx)
		open_sidebar(cx, nil, nil)
	end,
})

tern.command({
	id = "mirror",
	title = "Herdr: Toggle Tabs Mirror",
	icon = "user",
	keys = { "cmd+shift+m" },
	run = function(cx)
		if mirror_on() then
			stop_mirror(cx)
			cx:toast("info", "Herdr tabs closed", "Herdr keeps running")
		else
			tern.kv.set("mirror", {})
			sync_mirror(cx)
			cx:toast("success", "Herdr tabs mirrored")
		end
	end,
})

tern.command({
	id = "jump",
	title = "Herdr: Jump to Agent Needing Attention",
	icon = "user",
	keys = { "cmd+shift+j" },
	run = function(cx)
		local a = urgent()
		local snap = a and snaps[a.machine]
		local p = snap and a and snap.panes[a.pane_id]
		if p then
			show(cx, p)
		else
			cx:toast("info", "No Herdr agent is blocked or done")
		end
	end,
})

tern.chrome.tab_title(function(tab)
	if tab.name then
		return nil
	end
	local program = tab.program or ""
	if program ~= "herdr" and not string.match(program, "/herdr$") then
		return nil
	end
	local c = common.counts(all_agents())
	if c.blocked then
		return "herdr · " .. c.blocked .. " blocked"
	end
	return "herdr"
end)

-- window_start does not fire again on a plugin reload, so polling starts at load.
poll()
