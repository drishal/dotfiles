.pragma library

// Splits a markdown string into a sequence of segments:
//   { type: "text",  content: string, complete: true }
//   { type: "code",  content: string, language: string, complete: bool }
//   { type: "table", headers: [str], align: [str], rows: [[str]], weights: [int] }
//
// Fenced code blocks (``` ... ```) and GitHub-flavoured tables are extracted so
// they get dedicated renderers; everything else stays in a text segment for
// Qt's Text.MarkdownText (headers, lists, inline code, links, bold/italic…).
//
// Tables are pulled out because Qt's MarkdownText renderer both squishes them
// and mis-reports its implicitHeight, which under-sizes the surrounding bubble
// and makes following rows overlap. A custom TableBlock fixes both.
//
// During streaming a code fence may be unclosed — that segment is emitted with
// complete=false so the renderer can suppress chroma until the closing fence
// arrives.

// A line is a table row candidate if it contains a pipe that isn't the only
// content. We require the row to have at least one `|` separating cells.
function _looksLikeRow(line) {
    return line.indexOf("|") !== -1 && /\S/.test(line);
}

// The delimiter row under the header: every cell is dashes with optional
// leading/trailing colons, e.g. `| :--- | ---: | :--: |`.
function _isDelimiterRow(line) {
    if (line.indexOf("|") === -1) return false;
    const cells = _splitRow(line);
    if (cells.length === 0) return false;
    for (const c of cells) {
        if (!/^:?-+:?$/.test(c.trim())) return false;
    }
    return true;
}

// Split a `| a | b | c |` row into ["a","b","c"], tolerating missing outer
// pipes and honouring backslash-escaped pipes.
function _splitRow(line) {
    let s = line.trim();
    if (s.startsWith("|")) s = s.slice(1);
    if (s.endsWith("|") && !s.endsWith("\\|")) s = s.slice(0, -1);
    const cells = [];
    let cur = "";
    for (let k = 0; k < s.length; k++) {
        if (s[k] === "\\" && s[k + 1] === "|") { cur += "|"; k++; continue; }
        if (s[k] === "|") { cells.push(cur.trim()); cur = ""; continue; }
        cur += s[k];
    }
    cells.push(cur.trim());
    return cells;
}

function _alignOf(delimCell) {
    const c = delimCell.trim();
    const left = c.startsWith(":");
    const right = c.endsWith(":");
    if (left && right) return "center";
    if (right) return "right";
    return "left";
}

function segment(text) {
    if (!text) return [];

    const segments = [];
    const lines = text.split("\n");
    let i = 0;
    let textBuf = [];

    function flushText() {
        if (textBuf.length > 0) {
            const content = textBuf.join("\n");
            textBuf = [];
            // Skip whitespace-only buffers (e.g. the blank line a table or code
            // fence leaves behind) so they don't render an empty gap.
            if (/\S/.test(content)) {
                segments.push({
                    type: "text",
                    content: content,
                    language: "",
                    complete: true
                });
            }
        }
    }

    while (i < lines.length) {
        const line = lines[i];
        const fenceMatch = line.match(/^\s*```\s*(\S*)\s*$/);
        if (fenceMatch) {
            flushText();
            const lang = fenceMatch[1] || "";
            const codeLines = [];
            i++;
            let closed = false;
            while (i < lines.length) {
                if (lines[i].match(/^\s*```\s*$/)) {
                    closed = true;
                    i++;
                    break;
                }
                codeLines.push(lines[i]);
                i++;
            }
            segments.push({
                type: "code",
                content: codeLines.join("\n"),
                language: lang,
                complete: closed
            });
            continue;
        }

        // Table: a header row immediately followed by a delimiter row.
        if (_looksLikeRow(line) && i + 1 < lines.length && _isDelimiterRow(lines[i + 1])) {
            const headers = _splitRow(line);
            const align = _splitRow(lines[i + 1]).map(_alignOf);
            i += 2;
            const rows = [];
            while (i < lines.length && _looksLikeRow(lines[i]) && !_isDelimiterRow(lines[i])) {
                rows.push(_splitRow(lines[i]));
                i++;
            }
            const cols = headers.length;
            // Normalise every row to the header's column count.
            for (const r of rows) {
                while (r.length < cols) r.push("");
                if (r.length > cols) r.length = cols;
            }
            // Width weights from the longest cell per column (incl. header).
            const weights = [];
            for (let c = 0; c < cols; c++) {
                let m = (headers[c] || "").length;
                for (const r of rows) m = Math.max(m, (r[c] || "").length);
                weights.push(Math.max(3, m));
            }
            flushText();
            segments.push({
                type: "table",
                headers: headers,
                align: align,
                rows: rows,
                weights: weights
            });
            continue;
        }

        textBuf.push(line);
        i++;
    }
    flushText();

    return segments;
}
