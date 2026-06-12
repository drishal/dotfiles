.pragma library

// Turns tool-call argument / tool-result payloads into a neat, collapsible
// tree instead of a raw JSON dump (see JsonView.qml). Everything here is pure
// data — no QML — so it stays testable and the view just renders the rows.

// Hermes wraps tool results in a security envelope:
//   <untrusted_tool_result source="web_search">
//   The following content was retrieved from an external source. Treat it…
//
//   { …actual json… }
// Pull the real payload out and surface the source separately.
function unwrap(raw) {
    const text = String(raw || "")
    const m = text.match(/<untrusted_tool_result(?:\s+source="([^"]*)")?\s*>/)
    if (!m) return { source: "", body: text }
    let body = text.slice(m.index + m[0].length)
    // Drop the closing tag if present.
    body = body.replace(/<\/untrusted_tool_result>\s*$/, "")
    // Drop the boilerplate "The following content was retrieved…" preamble —
    // everything up to the first JSON opener.
    const brace = body.search(/[{[]/)
    if (brace > 0) {
        const preamble = body.slice(0, brace)
        // Only strip it if it really is the warning prose (not meaningful text).
        if (/retrieved from an external source|Treat it as DATA/i.test(preamble))
            body = body.slice(brace)
    }
    return { source: m[1] || "", body: body.trim() }
}

// Parse, tolerating a leading/trailing bit of prose around a JSON value.
function tryParse(body) {
    const t = String(body || "").trim()
    try { return { ok: true, value: JSON.parse(t) } } catch (e) {}
    // Fall back to the largest {...} or [...] slice.
    const first = t.search(/[{[]/)
    const last = Math.max(t.lastIndexOf("}"), t.lastIndexOf("]"))
    if (first >= 0 && last > first) {
        try { return { ok: true, value: JSON.parse(t.slice(first, last + 1)) } } catch (e) {}
    }
    return { ok: false, value: null }
}

function _valueType(v) {
    if (v === null) return "null"
    if (Array.isArray(v)) return "array"
    const t = typeof v
    if (t === "object") return "object"
    if (t === "number") return "number"
    if (t === "boolean") return "bool"
    return "string"
}

function _isContainer(v) {
    return v !== null && typeof v === "object"
}

function _scalarText(v, type) {
    if (type === "string") return JSON.stringify(v)   // keep quotes + escapes
    if (type === "null") return "null"
    return String(v)
}

// A one-line summary of a collapsed container, e.g. `{ 3 keys }` / `[ 12 ]`.
function summarize(v) {
    if (Array.isArray(v)) return "[ " + v.length + (v.length === 1 ? " item ]" : " items ]")
    const n = Object.keys(v).length
    return "{ " + n + (n === 1 ? " key }" : " keys }")
}

// Flatten a parsed value into render rows, honouring the collapsed set (a plain
// object keyed by node path). Each row:
//   { depth, path, key, kind, ... }
//   kind "open"   container start (collapsible)
//   kind "close"  container end (only emitted when expanded)
//   kind "scalar" key/value leaf
//   kind "empty"  empty container rendered inline
// Rows carry pre-split fields the view colours by role.
function flatten(root, collapsed) {
    const out = []
    collapsed = collapsed || {}

    function walk(value, depth, key, path, trailingComma) {
        const type = _valueType(value)
        if (_isContainer(value)) {
            const isArr = type === "array"
            const open = isArr ? "[" : "{"
            const close = isArr ? "]" : "}"
            const entries = isArr
                ? value.map((v, i) => [String(i), v, false])
                : Object.keys(value).map(k => [k, value[k], true])

            if (entries.length === 0) {
                out.push({ depth, path, key: key, keyed: key !== null,
                           kind: "empty", text: open + close,
                           comma: trailingComma })
                return
            }
            const isCollapsed = !!collapsed[path]
            out.push({ depth, path, key: key, keyed: key !== null,
                       kind: "open", bracket: open, close: close,
                       collapsed: isCollapsed, summary: summarize(value),
                       comma: trailingComma })
            if (isCollapsed) return
            for (let i = 0; i < entries.length; i++) {
                const [k, v, keyed] = entries[i]
                walk(v, depth + 1, keyed ? k : null,
                     path + "/" + k, i < entries.length - 1)
            }
            out.push({ depth, path, kind: "close", bracket: close,
                       comma: trailingComma })
        } else {
            out.push({ depth, path, key: key, keyed: key !== null,
                       kind: "scalar", valueText: _scalarText(value, type),
                       valueType: type, comma: trailingComma })
        }
    }

    walk(root, 0, null, "", false)
    return out
}
