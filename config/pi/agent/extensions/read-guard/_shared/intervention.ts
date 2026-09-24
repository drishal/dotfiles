// Vendored from little-coder (https://github.com/itayinbarr/little-coder),
// Apache-2.0 — see ./LICENSE. Modified: moved under read-guard/_shared/.

// Shared presentation for "harness intervention" events — the moments where
// little-coder's scaffolding overrides or redirects the model rather than the
// model deciding for itself (thinking-budget cap, write-guard redirect,
// turn-cap, finalize-warn, quality-monitor corrections, output-parser nudges).
//
// Before this helper each extension emitted its own free-form `ctx.ui.notify`
// in a different voice and severity, so a single harness decision (e.g. a
// thinking-budget abort) surfaced as several stacked warnings plus pi's own
// "Operation aborted" marker. Routing every such message through one helper
// gives the user a single, consistently-worded line:
//
//     harness intervention: the model has thought long enough — forcing it to
//     start implementing.
//
// This dir intentionally has no `index.ts`, so the launcher's extension
// auto-discovery (bin/little-coder.mjs: requires `<subdir>/index.ts`) skips
// it — it is a library imported by the real extensions, not an extension.

// Structurally typed so this helper has no hard dependency on pi's type
// surface and stays trivially mockable in unit tests.
export interface InterventionUI {
  notify(message: string, type?: "info" | "warning" | "error"): void;
}

export interface InterventionCtx {
  ui: InterventionUI;
}

/**
 * Surface a single, uniformly-formatted harness-intervention line to the user.
 *
 * @param ctx     Any object exposing `ui.notify` (the event-handler ctx).
 * @param message The human explanation of what the harness did and why,
 *                phrased as a continuation of "harness intervention: ".
 *                Lead with the consequence, e.g.
 *                "the model has thought long enough — forcing it to start
 *                implementing."
 */
export function harnessIntervention(ctx: InterventionCtx, message: string): void {
  ctx.ui.notify(`harness intervention: ${message}`, "info");
}
