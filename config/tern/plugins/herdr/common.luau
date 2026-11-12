-- Shared helpers for both halves: locating binaries, talking to Herdr on this machine or over ssh,
-- reading its state, and the links between Tern panes and the Herdr terminals they show.

local M = {}

local home = tern.getenv("HOME") or ""

local function find(env: string, candidates: { string }, fallback: string): string
	local override = tern.getenv(env)
	if override and override ~= "" then
		return override
	end
	for _, path in candidates do
		local ok, exists = pcall(tern.fs.exists, path)
		if ok and exists then
			return path
		end
	end
	return fallback
end

-- Tern windows and the daemon start from launchd, so PATH rarely holds ~/.local/bin.
M.herdr = find("HERDR_BIN", {
	home .. "/.local/bin/herdr",
	"/opt/homebrew/bin/herdr",
	"/usr/local/bin/herdr",
	home .. "/.cargo/bin/herdr",
}, "herdr")

M.tern = find("TERN_BIN", {
	"/Applications/Tern.app/Contents/MacOS/tern",
	home .. "/.local/bin/tern",
	"/usr/local/bin/tern",
	"/usr/bin/tern",
}, "tern")

local function config_dir(): string
	local base = tern.getenv("XDG_CONFIG_HOME")
	if not base or base == "" then
		base = home .. "/.config"
	end
	return base
end

local function read(path: string): string
	local ok, text = pcall(tern.fs.read, path)
	return ok and text or ""
end

-- Herdr's config.toml text, or "" when there is none.
function M.herdr_config(): string
	return read(config_dir() .. "/herdr/config.toml")
end

---------------------------------------------------------------------------------------------------
-- Machines: "local", then each ssh target in ~/.config/tern-herdr/machines (one per line, # comments).

function M.machines(): { string }
	local list = { "local" }
	for line in string.gmatch(read(config_dir() .. "/tern-herdr/machines") .. "\n", "([^\n]*)\n") do
		local target = string.match(line, "^%s*([^#%s]+)")
		if target and target ~= "local" and not table.find(list, target) then
			table.insert(list, target)
		end
	end
	return list
end

function M.quote(s: string): string
	return "'" .. string.gsub(s, "'", "'\\''") .. "'"
end

-- argv that runs `herdr ARGS…` on `machine`.
function M.argv(machine: string, args: { string }): { string }
	if machine == "local" then
		local argv = { M.herdr }
		for _, a in args do
			table.insert(argv, a)
		end
		return argv
	end
	local words = { "herdr" }
	for _, a in args do
		table.insert(words, M.quote(a))
	end
	return { "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", machine, table.concat(words, " ") }
end

-- argv that runs a plain command on `machine` (for git and the like).
function M.shell_argv(machine: string, args: { string }): { string }
	if machine == "local" then
		return args
	end
	local words = {}
	for _, a in args do
		table.insert(words, M.quote(a))
	end
	return { "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", machine, table.concat(words, " ") }
end

---------------------------------------------------------------------------------------------------
-- Integrations: Herdr marks one "available" when it isn't installed and the agent's command is
-- on PATH, and "update available" when it is outdated. Both put a dot on Herdr's menu.

local INTEGRATION_COMMANDS: { [string]: { string } } = {
	kilo = { "kilo", "kilo-code" },
	cursor = { "cursor-agent" },
	["antigravity-cli"] = { "agy" },
}

export type Integration = { name: string, state: string, available: boolean }

-- Reads `herdr integration status` and probes agent commands on `machine` in a login shell.
function M.integrations(machine: string, done: ({ Integration }?, string?) -> ())
	local names = { "pi", "omp", "claude", "codex", "copilot", "devin", "droid", "kimi", "opencode",
		"kilo", "hermes", "qodercli", "qwen", "cursor", "mastracode", "antigravity-cli", "grok", "letta" }
	local commands = {}
	for _, n in names do
		for _, c in INTEGRATION_COMMANDS[n] or { n } do
			table.insert(commands, c)
		end
	end
	local herdr_cmd = machine == "local" and M.quote(M.herdr) or "herdr"
	local script = herdr_cmd .. " integration status; echo '--- found'; for c in "
		.. table.concat(commands, " ") .. "; do command -v \"$c\" >/dev/null 2>&1 && echo \"$c\"; done"
	local argv
	if machine == "local" then
		argv = { tern.getenv("SHELL") or "/bin/zsh", "-lc", script }
	else
		argv = { "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", machine, "bash -lc " .. M.quote(script) }
	end
	tern.process.run(argv, { timeout_ms = 15000 }, function(res)
		if res.timed_out or not string.find(res.stdout, "--- found", 1, true) then
			done(nil, (string.gsub(res.stderr, "%s+$", "")))
			return
		end
		local status_text, found_text = string.match(res.stdout, "^(.-)%-%-%- found\n?(.*)$")
		local found = {}
		for c in string.gmatch(found_text or "", "%S+") do
			found[c] = true
		end
		local list = {}
		for line in string.gmatch(status_text or "", "[^\n]+") do
			local name, rest = string.match(line, "^([%w%-]+)[^:]*:%s*(.*)$")
			if name then
				local state = string.find(rest, "^current") and "current"
					or string.find(rest, "^outdated") and "outdated"
					or string.find(rest, "^not installed") and "missing"
					or "unknown"
				local available = false
				for _, c in INTEGRATION_COMMANDS[name] or { name } do
					available = available or found[c] == true
				end
				table.insert(list, { name = name, state = state, available = available })
			end
		end
		done(list, nil)
	end)
end

function M.needs_install(i: Integration): boolean
	return i.state == "outdated" or (i.state == "missing" and i.available)
end

---------------------------------------------------------------------------------------------------
-- State

M.STATES = { "blocked", "working", "done", "idle" }
M.RANK = { blocked = 1, working = 2, done = 3, idle = 4 }
M.TONE = { blocked = "error", working = "warn", done = "success", idle = "muted" }

export type Agent = {
	machine: string,
	pane_id: string,
	terminal_id: string,
	agent: string,
	status: string,
	title: string,
	cwd: string,
	workspace_id: string,
	tab_id: string,
	focused: boolean,
}

export type Workspace = { machine: string, id: string, label: string, number: number, status: string, active_tab: string?, focused: boolean }
export type Tab = { machine: string, id: string, workspace_id: string, label: string, number: number, status: string, focused: boolean }
export type Pane = { machine: string, id: string, key: string, terminal_id: string, tab_id: string, workspace_id: string, cwd: string }

export type Snapshot = {
	machine: string,
	err: string?,
	workspaces: { Workspace }, -- by number
	tabs: { Tab }, -- by workspace number, then tab number
	panes: { [string]: Pane }, -- by pane id
	agents: { Agent }, -- by urgency
}

local function failure(res: any): string?
	if res.timed_out then
		return "herdr timed out"
	end
	if res.status ~= 0 then
		local msg = (res.stderr ~= "" and res.stderr) or res.stdout
		return (string.gsub(msg, "%s+$", ""))
	end
	return nil
end

-- Decodes a Herdr CLI reply and returns `result[field]`, or nil and a reason.
function M.decode(res: any, field: string): (any, string?)
	local err = failure(res)
	if err then
		return nil, err
	end
	local ok, doc = pcall(tern.json.decode, res.stdout)
	if not ok or type(doc) ~= "table" then
		return nil, "unreadable herdr output"
	end
	if doc.error then
		return nil, tostring(doc.error.message or doc.error)
	end
	local value = doc.result and doc.result[field]
	if type(value) ~= "table" then
		return nil, "herdr returned no " .. field
	end
	return value, nil
end

function M.sort(agents: { Agent })
	table.sort(agents, function(x, y)
		local rx, ry = M.RANK[x.status] or 9, M.RANK[y.status] or 9
		if rx ~= ry then
			return rx < ry
		end
		return x.pane_id < y.pane_id
	end)
end

-- Turns `herdr pane list` rows into agents (rows without an agent are skipped).
function M.agents_from(machine: string, rows: { any }): { Agent }
	local agents = {}
	for _, a in rows do
		if a.agent then
			table.insert(agents, {
				machine = machine,
				pane_id = a.pane_id,
				terminal_id = a.terminal_id or "",
				agent = a.agent,
				status = a.agent_status or "idle",
				title = a.terminal_title_stripped or a.terminal_title or "",
				cwd = a.foreground_cwd or a.cwd or "",
				workspace_id = a.workspace_id or "",
				tab_id = a.tab_id or "",
				focused = a.focused == true,
			})
		end
	end
	M.sort(agents)
	return agents
end

local function build(machine: string, ws: any, ts: any, ps: any): Snapshot
	local snap: Snapshot = { machine = machine, err = nil, workspaces = {}, tabs = {}, panes = {}, agents = {} }
	for _, w in ws do
		table.insert(snap.workspaces, {
			machine = machine,
			id = w.workspace_id,
			label = w.label or w.workspace_id,
			number = w.number or 0,
			status = w.agent_status or "idle",
			active_tab = w.active_tab_id,
			focused = w.focused == true,
		})
	end
	table.sort(snap.workspaces, function(a, b)
		return a.number < b.number
	end)
	local order = {}
	for i, w in snap.workspaces do
		order[w.id] = i
	end
	for _, t in ts do
		table.insert(snap.tabs, {
			machine = machine,
			id = t.tab_id,
			workspace_id = t.workspace_id,
			label = t.label or tostring(t.number),
			number = t.number or 0,
			status = t.agent_status or "idle",
			focused = t.focused == true,
		})
	end
	table.sort(snap.tabs, function(a, b)
		local oa, ob = order[a.workspace_id] or 999, order[b.workspace_id] or 999
		if oa ~= ob then
			return oa < ob
		end
		return a.number < b.number
	end)
	for _, p in ps do
		snap.panes[p.pane_id] = {
			machine = machine,
			id = p.pane_id,
			key = machine .. "|" .. p.pane_id,
			terminal_id = p.terminal_id or "",
			tab_id = p.tab_id or "",
			workspace_id = p.workspace_id or "",
			cwd = p.foreground_cwd or p.cwd or "",
		}
	end
	snap.agents = M.agents_from(machine, ps)
	return snap
end

-- Reads one machine's workspaces, tabs and panes. `done` gets the snapshot and, in the window,
-- the cx of the last process callback.
function M.snapshot(machine: string, done: (Snapshot, any) -> ())
	local results: { [string]: any } = {}
	local got, err = 0, nil
	local function one(args: { string }, field: string)
		tern.process.run(M.argv(machine, args), { timeout_ms = 8000 }, function(res, cx)
			local value, why = M.decode(res, field)
			if value then
				results[field] = value
			else
				err = err or why
			end
			got += 1
			if got < 3 then
				return
			end
			if err then
				done({ machine = machine, err = err, workspaces = {}, tabs = {}, panes = {}, agents = {} }, cx)
			else
				done(build(machine, results.workspaces, results.tabs, results.panes), cx)
			end
		end)
	end
	one({ "workspace", "list" }, "workspaces")
	one({ "tab", "list" }, "tabs")
	one({ "pane", "list" }, "panes")
end

function M.tabs_of(snap: Snapshot, workspace_id: string): { Tab }
	local out = {}
	for _, t in snap.tabs do
		if t.workspace_id == workspace_id then
			table.insert(out, t)
		end
	end
	return out
end

function M.panes_of(snap: Snapshot, tab_id: string): { Pane }
	local out = {}
	for _, p in snap.panes do
		if p.tab_id == tab_id then
			table.insert(out, p)
		end
	end
	table.sort(out, function(a, b)
		return a.id < b.id
	end)
	return out
end

function M.pane_by_terminal(snap: Snapshot, terminal_id: string): Pane?
	for _, p in snap.panes do
		if p.terminal_id == terminal_id then
			return p
		end
	end
	return nil
end

function M.counts(agents: { Agent }): { [string]: number }
	local c = {}
	for _, a in agents do
		c[a.status] = (c[a.status] or 0) + 1
	end
	return c
end

function M.basename(path: string): string
	return string.match(path, "([^/]+)/*$") or path
end

function M.label(a: Agent): string
	if a.title ~= "" then
		return a.title
	end
	return a.agent .. " in " .. M.basename(a.cwd)
end

---------------------------------------------------------------------------------------------------
-- Links: a Tern pane running follow.sh shows the Herdr terminal named in its target file,
-- "MACHINE TERMINAL_ID". follow.sh writes `<file>.on` with the target it is attached to.

function M.target_file(link: string): string
	local dir = tern.plugin.data .. "/links"
	pcall(tern.fs.mkdir, dir)
	return dir .. "/" .. link
end

-- Shell command line for a terminal pane.
function M.follow_command(link: string): string
	return "sh " .. M.quote(tern.plugin.dir .. "/follow.sh") .. " " .. M.quote(M.target_file(link)) .. " " .. M.quote(M.herdr)
end

function M.encode_target(machine: string, terminal_id: string): string
	return machine .. " " .. terminal_id
end

-- The machine and terminal a link shows (or is about to). Old single-word targets are local.
function M.link_target(link: string): (string?, string?)
	local text = read(M.target_file(link))
	if text == "" then
		return nil, nil
	end
	local machine, terminal = string.match(text, "^(%S+) (%S+)$")
	if machine then
		return machine, terminal
	end
	return "local", text
end

-- Points a link's pane at a Herdr terminal. `write` types into the pane: ctrl+b q detaches the
-- current attach (Herdr's direct attach always takes it), and follow.sh attaches the new target.
function M.retarget(link: string, term: number?, machine: string, terminal_id: string, write: (number, string) -> ())
	local file = M.target_file(link)
	local target = M.encode_target(machine, terminal_id)
	tern.fs.write(file, target)
	local on = read(file .. ".on")
	if term and on ~= "" and on ~= target then
		write(term, "\x02q")
	end
end

function M.new_link(): string
	return string.format("%x%04x", math.floor(os.time()), math.random(0, 0xffff))
end

return M
