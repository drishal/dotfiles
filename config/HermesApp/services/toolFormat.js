.pragma library

// Helpers for turning raw tool-call args / tool-result JSON into a single-line
// pretty preview. Used by ChatArea.qml's tool_call and tool_result delegates so
// the chat doesn't show big blobs of `{"mode":"replace","new_string":"..."}`.

function _parseArgs(raw) {
    if (raw === undefined || raw === null) return null
    if (typeof raw === "object") return raw
    const s = String(raw).trim()
    if (!s) return null
    try { return JSON.parse(s) } catch (e) { return null }
}

function _collapseWs(s) {
    return String(s || "").replace(/\s+/g, " ").trim()
}

function _truncate(s, n) {
    s = _collapseWs(s)
    return s.length > n ? s.substring(0, n - 1) + "…" : s
}

function _basename(p) {
    if (!p) return ""
    const s = String(p)
    const i = s.lastIndexOf("/")
    return i >= 0 ? s.substring(i + 1) || s : s
}

function _shortenPath(p) {
    if (!p) return ""
    const s = String(p).replace(/^\/home\/[^/]+/, "~")
    if (s.length <= 48) return s
    const parts = s.split("/")
    if (parts.length <= 3) return s
    return parts.slice(0, 1).concat(["…"], parts.slice(-2)).join("/")
}

function iconFor(tool) {
    const t = String(tool || "").toLowerCase()
    if (t === "patch" || t === "edit" || t === "replace" || t === "str_replace") return "edit"
    if (t === "write" || t === "write_file" || t === "create_file" || t === "create") return "note_add"
    if (t === "read" || t === "read_file" || t === "view" || t === "cat") return "description"
    if (t === "terminal" || t === "bash" || t === "shell" || t === "run" || t === "exec") return "terminal"
    if (t === "search" || t === "grep" || t === "find" || t === "ripgrep" || t === "rg") return "search"
    if (t === "ls" || t === "list" || t === "list_directory" || t === "tree") return "folder_open"
    if (t === "glob") return "filter_alt"
    if (t === "fetch" || t === "web_fetch" || t === "http" || t === "url" || t === "curl") return "language"
    if (t === "delete" || t === "rm" || t === "remove") return "delete"
    if (t === "move" || t === "mv" || t === "rename") return "drive_file_move"
    if (t === "todo" || t === "task" || t === "plan") return "checklist"
    return "build"
}

// Returns { hint: string, detail: string }
//   hint   — short verb-ish badge ("replace", "$", "GET")
//   detail — main descriptor (file path, command, query)
function summarize(tool, rawArgs) {
    const t = String(tool || "").toLowerCase()
    const args = _parseArgs(rawArgs)

    if (!args) {
        return { hint: "", detail: _truncate(rawArgs, 80) }
    }

    if (t === "patch" || t === "edit" || t === "replace" || t === "str_replace") {
        const path = args.path || args.file || args.filename || args.file_path || ""
        const mode = args.mode || (args.old_string !== undefined ? "replace" : "")
        if (path) return { hint: mode || "patch", detail: _shortenPath(path) }
        const snip = args.new_string || args.old_string || args.diff || ""
        return { hint: mode || "patch", detail: _truncate(snip, 60) }
    }
    if (t === "write" || t === "write_file" || t === "create_file" || t === "create") {
        return { hint: "write", detail: _shortenPath(args.path || args.file || args.file_path || "") }
    }
    if (t === "read" || t === "read_file" || t === "view" || t === "cat") {
        const path = args.path || args.file || args.file_path || ""
        const range = (args.offset || args.start_line) ? (" :" + (args.offset || args.start_line)) : ""
        return { hint: "read", detail: _shortenPath(path) + range }
    }
    if (t === "terminal" || t === "bash" || t === "shell" || t === "run" || t === "exec") {
        const cmd = args.command || args.cmd || args.script || args.input || ""
        return { hint: "$", detail: _truncate(cmd, 90) }
    }
    if (t === "search" || t === "grep" || t === "find" || t === "ripgrep" || t === "rg") {
        const q = args.query || args.pattern || args.q || args.regex || ""
        const where = args.path ? "  in " + _shortenPath(args.path) : ""
        return { hint: "find", detail: _truncate(q + where, 80) }
    }
    if (t === "glob") {
        return { hint: "glob", detail: _truncate(args.pattern || args.glob || "", 80) }
    }
    if (t === "ls" || t === "list" || t === "list_directory" || t === "tree") {
        return { hint: "ls", detail: _shortenPath(args.path || ".") }
    }
    if (t === "fetch" || t === "web_fetch" || t === "http" || t === "url" || t === "curl") {
        return { hint: args.method || "GET", detail: _truncate(args.url || args.uri || "", 80) }
    }
    if (t === "delete" || t === "rm" || t === "remove") {
        return { hint: "rm", detail: _shortenPath(args.path || args.file || "") }
    }
    if (t === "move" || t === "mv" || t === "rename") {
        return { hint: "mv", detail: _shortenPath(args.from || args.src || "") + " → " + _shortenPath(args.to || args.dst || "") }
    }
    if (t === "todo" || t === "task" || t === "plan") {
        const items = args.items || args.tasks || args.todos
        if (Array.isArray(items)) return { hint: "todo", detail: items.length + " item" + (items.length === 1 ? "" : "s") }
    }

    // Generic fallback — pick the first meaningful field
    const keys = ["path", "file", "file_path", "url", "uri", "query", "pattern", "command", "input", "name", "title", "message", "text"]
    for (const k of keys) {
        if (args[k] !== undefined && args[k] !== null && args[k] !== "") {
            return { hint: "", detail: _truncate(String(args[k]), 80) }
        }
    }
    for (const k in args) {
        const v = args[k]
        if (typeof v === "string" || typeof v === "number" || typeof v === "boolean") {
            return { hint: "", detail: k + ": " + _truncate(String(v), 60) }
        }
    }
    return { hint: "", detail: "" }
}

// Result-row header summary. Returns { success: bool, detail: string }
function summarizeResult(tool, rawContent) {
    if (!rawContent) return { success: true, detail: "" }
    const s = String(rawContent)
    let obj = null
    try { obj = JSON.parse(s) } catch (e) {}

    if (obj && typeof obj === "object" && !Array.isArray(obj)) {
        if (obj.error) {
            return { success: false, detail: _truncate(typeof obj.error === "string" ? obj.error : JSON.stringify(obj.error), 80) }
        }
        const success = obj.success !== false
        if (obj.diff) {
            const lines = String(obj.diff).split("\n")
            let added = 0, removed = 0
            for (const ln of lines) {
                if (ln.startsWith("+") && !ln.startsWith("+++")) added++
                else if (ln.startsWith("-") && !ln.startsWith("---")) removed++
            }
            return { success: success, detail: "+" + added + " −" + removed }
        }
        if (obj.output !== undefined && obj.output !== null) {
            const o = String(obj.output)
            const lc = o.split("\n").length
            return { success: success, detail: lc + " line" + (lc === 1 ? "" : "s") }
        }
        if (obj.stdout !== undefined || obj.stderr !== undefined) {
            const out = String(obj.stdout || "") + (obj.stderr ? String(obj.stderr) : "")
            const lc = out.split("\n").filter(Boolean).length
            return { success: success, detail: lc + " line" + (lc === 1 ? "" : "s") }
        }
        if (Array.isArray(obj.results)) {
            return { success: success, detail: obj.results.length + " result" + (obj.results.length === 1 ? "" : "s") }
        }
        if (Array.isArray(obj.matches)) {
            return { success: success, detail: obj.matches.length + " match" + (obj.matches.length === 1 ? "" : "es") }
        }
        if (Array.isArray(obj.files)) {
            return { success: success, detail: obj.files.length + " file" + (obj.files.length === 1 ? "" : "s") }
        }
        if (obj.lines !== undefined) {
            return { success: success, detail: obj.lines + " lines" }
        }
        return { success: success, detail: success ? "ok" : "failed" }
    }

    if (Array.isArray(obj)) {
        return { success: true, detail: obj.length + " item" + (obj.length === 1 ? "" : "s") }
    }

    const lc = s.split("\n").length
    return { success: true, detail: lc + " line" + (lc === 1 ? "" : "s") }
}
