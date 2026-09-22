import type { SessionEntry } from "@mariozechner/pi-coding-agent";
import { WATCHDOG_ANSWER_TOOL } from "./model.ts";

// Pattern catalog: PATTERNS.md — update when adding/removing/changing detection patterns.

export interface RalphPromptInfo {
	key: string;
	loop?: string;
	iteration?: number;
	maxIterations?: number;
	sourceEntryId?: string;
	timestamp: number;
}

export interface RalphBranchAnalysis {
	prompt?: RalphPromptInfo;
	ralphDoneAfterPrompt: boolean;
	latestAssistantText?: string;
	latestAssistantHasToolCall: boolean;
	shouldRecover: boolean;
	reason?: string;
}

export interface AssistantStallAnalysis {
	latestAssistantEntryId?: string;
	latestAssistantText?: string;
	latestAssistantHasToolCall: boolean;
	shouldRecover: boolean;
	streak: number;
	reason?: string;
	hadToolResultSincePreviousUser?: boolean;
}

export interface CompactionRecoveryAnalysis {
	shouldRecover: boolean;
	kind?: "overflow" | "ralph";
	reason: string;
	ralph?: RalphBranchAnalysis;
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function isContextLengthError(message: string | undefined): boolean {
	return message?.includes("context_length_exceeded") === true
		|| message?.includes("exceeds the context window") === true
		|| message?.includes("ContextWindowExceededError") === true
		|| message?.includes("maximum context length") === true;
}

export function assistantStoppedForContextLimit(message: unknown): boolean {
	const stopReason = isRecord(message) && message.role === "assistant" && typeof message.stopReason === "string" ? message.stopReason : undefined;
	return stopReason === "length" || (stopReason === "error" && isContextLengthError(isRecord(message) && typeof message.errorMessage === "string" ? message.errorMessage : undefined));
}

function textFromContent(content: unknown): string {
	if (typeof content === "string") return content;
	if (Array.isArray(content)) return content.map(textFromContent).filter(Boolean).join("\n");
	if (!isRecord(content)) return "";

	const type = typeof content.type === "string" ? content.type : undefined;
	if ((type === undefined || type === "text") && typeof content.text === "string") return content.text;
	if ("content" in content) return textFromContent(content.content);
	return "";
}

export function messageText(messageOrContent: unknown): string {
	const content = isRecord(messageOrContent) && "content" in messageOrContent ? messageOrContent.content : messageOrContent;
	return textFromContent(content).trim();
}

function messageRole(message: unknown): string | undefined {
	return isRecord(message) && typeof message.role === "string" ? message.role : undefined;
}

function messageToolName(message: unknown): string | undefined {
	return isRecord(message) && typeof message.toolName === "string" ? message.toolName : undefined;
}

function messageIsError(message: unknown): boolean {
	return isRecord(message) && message.isError === true;
}

function contentBlocks(message: unknown): unknown[] {
	if (!isRecord(message)) return [];
	return Array.isArray(message.content) ? message.content : [];
}

export function messageHasToolCall(message: unknown, toolName?: string): boolean {
	return contentBlocks(message).some((block) => {
		if (!isRecord(block)) return false;
		const type = typeof block.type === "string" ? block.type : undefined;
		if (type !== "toolCall" && type !== "tool_use") return false;
		return toolName ? block.name === toolName : true;
	});
}

function toolCallBlocks(message: unknown): Array<Record<string, unknown>> {
	return contentBlocks(message).filter((block): block is Record<string, unknown> => {
		if (!isRecord(block)) return false;
		const type = typeof block.type === "string" ? block.type : undefined;
		return type === "toolCall" || type === "tool_use";
	});
}

function hasNonWatchdogToolCall(message: unknown): boolean {
	return toolCallBlocks(message).some((block) => block.name !== WATCHDOG_ANSWER_TOOL);
}

function watchdogAnswerDoneValue(message: unknown): boolean | undefined {
	for (const block of toolCallBlocks(message)) {
		if (block.name !== WATCHDOG_ANSWER_TOOL) continue;
		const args = isRecord(block.arguments) ? block.arguments : undefined;
		if (typeof args?.done === "boolean") return args.done;
	}
	return undefined;
}

function isRalphDoneToolResultMessage(message: unknown): boolean {
	return messageRole(message) === "toolResult" && messageToolName(message) === "ralph_done" && !messageIsError(message);
}

export function isRalphLoopPromptText(text: string): boolean {
	return /RALPH LOOP:/i.test(text) || (/You are in a Ralph loop/i.test(text) && /ralph_done/i.test(text));
}

export function isStardockLoopPromptText(text: string): boolean {
	return /STARDOCK LOOP:/i.test(text) || (/You are in a Stardock loop/i.test(text) && /stardock_done/i.test(text));
}

function parsePositiveInt(value: string | undefined): number | undefined {
	if (!value) return undefined;
	const parsed = Number(value);
	return Number.isInteger(parsed) && parsed > 0 ? parsed : undefined;
}

function makeRalphPromptKey(text: string, prompt: Omit<RalphPromptInfo, "key">): string {
	if (prompt.sourceEntryId) return prompt.sourceEntryId;
	const fingerprint = text.replace(/\s+/g, " ").slice(0, 80);
	return `${prompt.loop ?? "unknown"}:${prompt.iteration ?? 0}:${fingerprint}`;
}

export function parseRalphPrompt(text: string, timestamp = Date.now(), sourceEntryId?: string): RalphPromptInfo | undefined {
	if (!isRalphLoopPromptText(text)) return undefined;

	const header = text.match(/RALPH LOOP:\s*([^|\n]+)(?:\s*\|\s*Iteration\s+(\d+)\/(\d+))?/i);
	const instructionIteration = text.match(/You are in a Ralph loop\s*\(iteration\s+(\d+)\s+of\s+(\d+)\)/i);
	const taskFile = text.match(/\.ralph\/([^\s)]+)\b/i);
	const loop = (header?.[1] ?? taskFile?.[1]?.replace(/\.md$/i, ""))?.trim();
	const iteration = parsePositiveInt(header?.[2]) ?? parsePositiveInt(instructionIteration?.[1]);
	const maxIterations = parsePositiveInt(header?.[3]) ?? parsePositiveInt(instructionIteration?.[2]);
	const prompt = { loop, iteration, maxIterations, sourceEntryId, timestamp };
	return { ...prompt, key: makeRalphPromptKey(text, prompt) };
}

export function assistantRequestsContinuation(text: string): boolean {
	const normalized = text.replace(/[’]/g, "'").trim().toLowerCase();
	if (!normalized) return false;
	if (normalized.includes("<promise>complete</promise>")) return false;
	if (/\b(blocked|paused|waiting for|cannot proceed|can't proceed|unable to proceed)\b/.test(normalized)) return false;
	if (/\bneed (your|user) (input|decision|confirmation|approval)\b/.test(normalized)) return false;
	if (/\bplease (confirm|advise|decide)|\bshould i\b|\bdo you want\b/.test(normalized)) return false;

	return [
		/\bi('ll| will)\s+(do|record|update|continue|proceed|work|start|run|check|inspect|implement|create|capture|execute)\b/,
		/\bi('m| am)\s+(proceeding|continuing|working|going to|gonna|on it)\b/,
		/\bproceeding with (that|this|it) now\b/,
		/\bcontinue with (the )?(next|current|this)\b/,
		/\bnext[, ]+i('ll| will)\b/,
		/\blet me\s+(continue|proceed|check|run|update|record|implement|start|execute)\b/,
		/\blet('s| us)\s+(continue|proceed|check|run|update|record|implement|start|execute|inspect|create|capture|do)\b/,
	].some((pattern) => pattern.test(normalized));
}

export function assistantRequestsRalphContinuation(text: string): boolean {
	return assistantRequestsContinuation(text);
}

export function userRequestsSimpleContinuation(text: string): boolean {
	const normalized = text.replace(/[’]/g, "'").trim().toLowerCase();
	if (!normalized) return false;
	return [
		/^continue\b/,
		/^keep going\b/,
		/^go on\b/,
		/^carry on\b/,
		/^resume\b/,
		/^proceed\b/,
		/\bjust continue\b/,
		/\bcontinue working\b/,
		/\bdo not acknowledge me\b/,
	].some((pattern) => pattern.test(normalized));
}

function isBlankAssistantStop(message: unknown): boolean {
	return messageRole(message) === "assistant" && messageText(message).length === 0 && !messageHasToolCall(message);
}

export function shouldRecoverStalledAssistantTurn(message: unknown, options?: { hadToolResultSincePreviousUser?: boolean }): boolean {
	if (isRecord(message) && message.stopReason === "aborted") return false;
	// A 400 ContextWindowExceededError means the request NEVER SUCCEEDED — input +
	// max_tokens exceeded the provider's hard cap. Nudging re-sends the same oversized
	// request and loops (each nudge adds ~191 tokens, making it worse). Must be checked
	// BEFORE the blank-stop path: a 400 produces empty content [] which would otherwise
	// match isBlankAssistantStop and trigger a looping nudge. Let native overflow
	// recovery (or the user) handle it.
	if (isRecord(message) && message.role === "assistant" && message.stopReason === "error"
		&& isContextLengthError(typeof message.errorMessage === "string" ? message.errorMessage : undefined)) {
		return false;
	}
	// Output TRUNCATION (stopReason "length") — the model was mid-generation and got cut
	// off. This IS recoverable: the model can continue from where it stopped.
	if (isRecord(message) && message.role === "assistant" && message.stopReason === "length") return true;
	if (hasNonWatchdogToolCall(message)) return false;
	const watchdogDone = watchdogAnswerDoneValue(message);
	if (watchdogDone === true) return false;
	if (watchdogDone === false) return true;
	if (assistantRequestsContinuation(messageText(message))) return true;
	return isBlankAssistantStop(message) && options?.hadToolResultSincePreviousUser !== true;
}

export function shouldRecoverStalledRalphTurn(message: unknown): boolean {
	return shouldRecoverStalledAssistantTurn(message);
}

export function analyzeLatestAssistantStall(entries: SessionEntry[]): AssistantStallAnalysis {
	const latest = entries.at(-1);
	const message = latest ? entryMessage(latest) : undefined;
	if (!latest || !message || messageRole(message) !== "assistant") {
		return { latestAssistantHasToolCall: false, shouldRecover: false, streak: 0 };
	}

	let hadToolResultSincePreviousUser = false;
	for (let i = entries.length - 2; i >= 0; i -= 1) {
		const priorMessage = entryMessage(entries[i]);
		if (!priorMessage) continue;
		if (messageRole(priorMessage) === "user") break;
		if (messageRole(priorMessage) === "toolResult") hadToolResultSincePreviousUser = true;
	}

	const latestAssistantText = messageText(message);
	const latestAssistantHasToolCall = messageHasToolCall(message);
	const shouldRecover = shouldRecoverStalledAssistantTurn(message, { hadToolResultSincePreviousUser });
	const blankWithoutToolProgress = isBlankAssistantStop(message) && !hadToolResultSincePreviousUser;
	return {
		latestAssistantEntryId: latest.id,
		latestAssistantText,
		latestAssistantHasToolCall,
		shouldRecover,
		streak: shouldRecover ? 1 : 0,
		reason: shouldRecover ? (blankWithoutToolProgress ? "blank-assistant-without-tool-progress" : "assistant-promised-continuation") : undefined,
		hadToolResultSincePreviousUser,
	};
}

function entryMessage(entry: SessionEntry): unknown | undefined {
	return entry.type === "message" ? entry.message : undefined;
}

export function analyzeRalphBranchForStall(entries: SessionEntry[], timestamp = Date.now()): RalphBranchAnalysis {
	let promptIndex = -1;
	let prompt: RalphPromptInfo | undefined;

	for (let i = entries.length - 1; i >= 0; i -= 1) {
		const entry = entries[i];
		const message = entryMessage(entry);
		if (!message || messageRole(message) !== "user") continue;
		const candidate = parseRalphPrompt(messageText(message), timestamp, entry.id);
		if (!candidate) continue;
		promptIndex = i;
		prompt = candidate;
		break;
	}

	if (!prompt) {
		return { ralphDoneAfterPrompt: false, latestAssistantHasToolCall: false, shouldRecover: false };
	}

	let ralphDoneAfterPrompt = false;
	let latestAssistant: unknown;
	for (let i = promptIndex + 1; i < entries.length; i += 1) {
		const message = entryMessage(entries[i]);
		if (!message) continue;
		if (isRalphDoneToolResultMessage(message)) ralphDoneAfterPrompt = true;
		if (messageRole(message) === "assistant") latestAssistant = message;
	}

	const latestAssistantText = latestAssistant ? messageText(latestAssistant) : undefined;
	const latestAssistantHasToolCall = latestAssistant ? messageHasToolCall(latestAssistant) : false;
	let hadToolResultSincePrompt = false;
	for (let i = promptIndex + 1; i < entries.length; i += 1) {
		const candidate = entryMessage(entries[i]);
		if (candidate && messageRole(candidate) === "toolResult") hadToolResultSincePrompt = true;
	}
	const shouldRecover = Boolean(latestAssistant && !ralphDoneAfterPrompt && shouldRecoverStalledAssistantTurn(latestAssistant, { hadToolResultSincePreviousUser: hadToolResultSincePrompt }));
	return {
		prompt,
		ralphDoneAfterPrompt,
		latestAssistantText,
		latestAssistantHasToolCall,
		shouldRecover,
		reason: shouldRecover ? "assistant-promised-ralph-continuation" : undefined,
	};
}

export function analyzeCompactionRecovery(
	entriesBeforeCompaction: SessionEntry[],
	options: { hasActiveLoop: boolean; isOverflow: boolean; timestamp?: number },
): CompactionRecoveryAnalysis {
	const ralph = analyzeRalphBranchForStall(entriesBeforeCompaction, options.timestamp ?? Date.now());

	if (options.isOverflow) {
		return {
			shouldRecover: true,
			kind: options.hasActiveLoop && ralph.prompt && !ralph.ralphDoneAfterPrompt ? "ralph" : "overflow",
			reason: "context-overflow-compaction",
			ralph,
		};
	}

	if (!options.hasActiveLoop) {
		return { shouldRecover: false, reason: "no-active-ralph-loop", ralph };
	}

	if (!ralph.prompt) {
		return { shouldRecover: false, reason: "active-loop-not-present-in-session-branch", ralph };
	}

	if (ralph.ralphDoneAfterPrompt) {
		return { shouldRecover: false, reason: "ralph-done-after-latest-prompt", ralph };
	}

	if (ralph.shouldRecover) {
		return { shouldRecover: true, kind: "ralph", reason: ralph.reason ?? "ralph-branch-appears-resumable", ralph };
	}

	if (!ralph.latestAssistantText) {
		return { shouldRecover: true, kind: "ralph", reason: "ralph-prompt-has-no-assistant-response", ralph };
	}

	return { shouldRecover: false, reason: "latest-ralph-assistant-did-not-request-continuation", ralph };
}
