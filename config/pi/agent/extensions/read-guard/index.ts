// Vendored from little-coder (https://github.com/itayinbarr/little-coder),
// Apache-2.0 — see ./LICENSE. Modified: import path rewritten to ./_shared/intervention.ts.

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { harnessIntervention } from "./_shared/intervention.ts";

// Harness intervention: trim a `read` result that would overflow the context window.
//
// little-coder drives SMALL local models with small context windows (the
// model's registered contextWindow, read live below via getContextUsage()).
// pi's built-in `read` returns up to ~2000 lines in a single tool result
// — for a small model that one result can blow past the remaining budget, evict
// earlier conversation, and wreck the run. That's exactly the class of failure
// the harness-intervention layer exists to catch (cf. thinking-budget cap,
// write-guard redirect, turn-cap).
//
// When a read result would push context usage past the window, we replace it
// with only the file's first HEAD_LINES lines plus a message telling the model
// why it was trimmed and to use those lines to understand the structure, then
// locate what it needs with grep/find or a targeted read (offset/limit) — rather
// than re-reading the whole file. The user sees one uniform "harness
// intervention: …" line, like every other intervention.
//
// Why `tool_result`, not `tool_call`: a `tool_call` handler can only `block`
// with a `reason` string (no file content) or mutate `input.limit` (lines but no
// message). Delivering BOTH the first 30 lines AND an explanation in one result
// requires `tool_result`, whose return value replaces the content the model sees
// (ToolResultEventResult.content). The full file is still read from disk (pi
// already caps that at ~2000 lines) but the oversized text never reaches the LLM
// context because we swap it out before it lands.

export const HEAD_LINES = 30;

// When current context usage is unknown (e.g. right after compaction
// getContextUsage().tokens is null), fall back to "a single file should never
// eat more than this fraction of the whole window".
export const FALLBACK_FRACTION = 0.5;

// Tokens to keep in reserve below the window before we call a read an overflow.
// 0 = trim only on literal overflow; raise it to trim slightly earlier and leave
// the model headroom to act on the 30 lines.
export const RESERVE = 0;

/** chars→tokens estimate. Same 3.5 ratio as thinking-budget's charsToTokens /
 *  local/context_manager.estimate_tokens. */
export function estimateTokens(chars: number): number {
  return Math.ceil(chars / 3.5);
}

/** First `n` lines of `text`, preserving pi's `cat -n` line-number prefixes so
 *  the model keeps a real structural view. Safe when text has fewer than n. */
export function firstLines(text: string, n: number): string {
  return text.split("\n").slice(0, n).join("\n");
}

export function countLines(text: string): number {
  if (text === "") return 0;
  return text.split("\n").length;
}

/**
 * Decide whether a read result should be trimmed because keeping it whole would
 * exceed the context window.
 *
 * - Nothing to trim if the result is already <= headN lines, or we have no window.
 * - With a known current token count: trim when current + est would cross the
 *   window (less RESERVE) — the literal "will result in exceeding the window".
 * - With unknown current usage: trim when the result alone exceeds
 *   FALLBACK_FRACTION of the window.
 */
export function shouldTrimRead(a: {
  contentChars: number;
  currentTokens: number | null;
  contextWindow: number;
  lineCount: number;
  headN: number;
}): boolean {
  if (!a.contextWindow) return false;
  if (a.lineCount <= a.headN) return false;
  const est = estimateTokens(a.contentChars);
  if (a.currentTokens == null) {
    return est > a.contextWindow * FALLBACK_FRACTION;
  }
  return a.currentTokens + est > a.contextWindow - RESERVE;
}

/** Message appended below the 30 lines, addressed to the model. Leads with the
 *  consequence and the directive. */
export function trimmedReadMessage(a: {
  shownLines: number;
  totalLines: number;
  estTokens: number;
  contextWindow: number;
}): string {
  return (
    `⚠️ This file is too large to read in full — reading all ${a.totalLines} lines ` +
    `(~${a.estTokens} tokens) would exceed the remaining context window ` +
    `(${a.contextWindow} tokens). Only the first ${a.shownLines} lines are shown above.\n` +
    `\n` +
    `Use these ${a.shownLines} lines to understand the file's structure, then narrow down ` +
    `instead of reading the whole thing:\n` +
    `  • search for what you need with \`grep\` (by content) or \`find\` (by name), then\n` +
    `  • \`read\` only the relevant range with \`offset\` and \`limit\`.\n` +
    `\n` +
    `Do NOT re-read this file in full — it will be trimmed again.`
  );
}

type TextOrImage = { type: string; text?: string };

export default function (pi: ExtensionAPI) {
  pi.on("tool_result", async (event, ctx) => {
    if (String((event as any).toolName ?? "").toLowerCase() !== "read") return;
    if ((event as any).isError) return;

    const content = (((event as any).content ?? []) as TextOrImage[]);
    if (content.length === 0) return;
    // Text-only: an image read can't be line-trimmed, leave it alone.
    if (content.some((c) => c.type !== "text")) return;
    const text = content.map((c) => c.text ?? "").join("");

    // getContextUsage may be absent on older SDK builds; without a window we
    // can't judge overflow, so leave the result untouched.
    const usage =
      typeof ctx.getContextUsage === "function" ? ctx.getContextUsage() : undefined;
    if (!usage?.contextWindow) return;

    const lineCount = countLines(text);
    if (
      !shouldTrimRead({
        contentChars: text.length,
        currentTokens: usage.tokens,
        contextWindow: usage.contextWindow,
        lineCount,
        headN: HEAD_LINES,
      })
    ) {
      return;
    }

    const head = firstLines(text, HEAD_LINES);
    const msg = trimmedReadMessage({
      shownLines: HEAD_LINES,
      totalLines: lineCount,
      estTokens: estimateTokens(text.length),
      contextWindow: usage.contextWindow,
    });

    harnessIntervention(
      ctx,
      "a read would have overflowed the context window — showed only the file's first 30 lines and told the model to search it instead.",
    );

    return { content: [{ type: "text" as const, text: head + "\n\n" + msg }] };
  });
}
