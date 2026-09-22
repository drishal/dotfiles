export type WatchdogNudgeKind = "overflow" | "ralph" | "assistant-stall";

export interface WatchdogNudgeDetails {
	kind: "watchdog_nudge";
	recoveryKind: WatchdogNudgeKind;
	title: string;
	reason: string;
	loop?: string;
	iteration?: number;
	compactionId?: string;
	promptKey?: string;
}

export interface WatchdogNudgeRequest {
	content: string;
	details: WatchdogNudgeDetails;
	entry: Record<string, unknown>;
	notification: string;
}

export const RECOVERY_DELAY_MS = 1_000;
export const ASSISTANT_IDLE_DELAY_MS = 2_000;
export const MAX_ASSISTANT_IDLE_RECOVERIES_PER_STREAK = 3;
export const MESSAGE_TYPE_WATCHDOG_NUDGE = "compaction-continue:watchdog-nudge";
export const WATCHDOG_ANSWER_TOOL = "watchdog_answer";

export function buildWatchdogNudgePrompt(hasActiveLoop: boolean): string {
	const body = [
		"Automated watchdog nudge: Pi became idle after compaction or after a stalled turn.",
		"This is not a new user request and does not mean more work is required.",
		`Do not acknowledge this nudge in prose and do not reason about the user's original prompt. Answer \`${WATCHDOG_ANSWER_TOOL}(done: true)\` unless the user's last explicit request is visibly incomplete (test failures, uncommitted implementation that was asked for, a pending direct question). Background context, verification ideas, or follow-up curiosities are not unfinished work.`,
	];

	if (hasActiveLoop) {
		body.push(
			"If you answered `done: true`, stop after the tool call and emit the loop completion marker (`<promise>COMPLETE</promise>`) to signal the loop is fully complete. If you answered `done: false`, continue from the next concrete step instead of replying about the nudge.",
		);
	} else {
		body.push(
			"If you answered `done: true`, stop after the tool call — do not emit `<promise>COMPLETE</promise>`, as there is no active loop. If you answered `done: false`, continue from the next concrete step instead of replying about the nudge.",
		);
	}

	return body.join("\n\n");
}

/** @deprecated Use buildWatchdogNudgePrompt(hasActiveLoop) instead. */
export const WATCHDOG_NUDGE_PROMPT = buildWatchdogNudgePrompt(true);
