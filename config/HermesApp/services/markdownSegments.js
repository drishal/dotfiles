.pragma library

// Splits a markdown string into a sequence of segments:
//   { type: "text", content: string, complete: true }
//   { type: "code", content: string, language: string, complete: bool }
//
// Only fenced code blocks (``` ... ```) are extracted. Everything else stays in
// a text segment as-is so Qt's Text.MarkdownText can render headers, lists,
// inline code, links, bold/italic, blockquotes, etc.
//
// During streaming a code fence may be unclosed — that segment is emitted with
// complete=false so the renderer can suppress chroma until the closing fence
// arrives.
function segment(text) {
    if (!text) return [];

    const segments = [];
    const lines = text.split("\n");
    let i = 0;
    let textBuf = [];

    function flushText() {
        if (textBuf.length > 0) {
            segments.push({
                type: "text",
                content: textBuf.join("\n"),
                language: "",
                complete: true
            });
            textBuf = [];
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
        } else {
            textBuf.push(line);
            i++;
        }
    }
    flushText();

    return segments;
}
