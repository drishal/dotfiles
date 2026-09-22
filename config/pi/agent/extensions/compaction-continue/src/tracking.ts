import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";

export type TrackingEventKind = "watchdog_candidate" | "watchdog_nudge" | "watchdog_skip" | "watchdog_answer";
export type TrackingSource = "compaction" | "assistant-stall";

export interface TrackingConfig {
	enabled: boolean;
	appendSessionEntries: boolean;
	log: boolean;
	maxRecentEvents: number;
}

export interface LoadedTrackingConfig {
	config: TrackingConfig;
	paths: string[];
	diagnostics: string[];
}

interface TrackingEventBase {
	version: 1;
	kind: TrackingEventKind;
	timestamp: string;
	sessionId: string;
	repoRoot: string;
	source?: TrackingSource;
	recoveryKind?: string;
	reason?: string;
	loop?: string;
	iteration?: number;
	compactionId?: string;
}

export interface WatchdogCandidateEvent extends TrackingEventBase {
	kind: "watchdog_candidate";
}

export interface WatchdogNudgeEvent extends TrackingEventBase {
	kind: "watchdog_nudge";
}

export interface WatchdogSkipEvent extends TrackingEventBase {
	kind: "watchdog_skip";
	skipReason: string;
}

export interface WatchdogAnswerEvent extends TrackingEventBase {
	kind: "watchdog_answer";
	done: boolean;
	confidence?: string;
	note?: string;
	noteLength?: number;
	noteHash?: string;
}

export type TrackingEvent = WatchdogCandidateEvent | WatchdogNudgeEvent | WatchdogSkipEvent | WatchdogAnswerEvent;
export type TrackingEventInput =
	| Omit<WatchdogCandidateEvent, "version" | "timestamp" | "sessionId" | "repoRoot">
	| Omit<WatchdogNudgeEvent, "version" | "timestamp" | "sessionId" | "repoRoot">
	| Omit<WatchdogSkipEvent, "version" | "timestamp" | "sessionId" | "repoRoot">
	| Omit<WatchdogAnswerEvent, "version" | "timestamp" | "sessionId" | "repoRoot">;

const CONFIG_FILE_NAME = "compaction-continue.json";
export const DEFAULT_TRACKING_CONFIG: TrackingConfig = {
	enabled: false,
	appendSessionEntries: true,
	log: true,
	maxRecentEvents: 20,
};

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function stringValue(value: unknown): string | undefined {
	return typeof value === "string" ? value : undefined;
}

function booleanValue(value: unknown): boolean | undefined {
	return typeof value === "boolean" ? value : undefined;
}

function numberValue(value: unknown): number | undefined {
	return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function safeSessionPathSegment(sessionId: string): string {
	return sessionId.replace(/[^a-zA-Z0-9._-]+/g, "_").slice(0, 160) || "unknown";
}

function trackingLogDir(): string {
	return process.env.PI_COMPACTION_CONTINUE_DIR ?? path.join(process.env.XDG_CACHE_HOME ?? path.join(os.homedir(), ".cache"), "pi-compaction-continue");
}

export function trackingLogPath(sessionId = "unknown"): string {
	return process.env.PI_COMPACTION_CONTINUE_LOG ?? path.join(trackingLogDir(), `${safeSessionPathSegment(sessionId)}.jsonl`);
}

function agentDir(): string {
	return process.env.PI_CODING_AGENT_DIR ?? process.env.PI_AGENT_DIR ?? path.join(os.homedir(), ".pi", "agent");
}

function configPaths(ctx: ExtensionContext): string[] {
	const paths: string[] = [];
	if (process.env.PI_COMPACTION_CONTINUE_CONFIG) paths.push(process.env.PI_COMPACTION_CONTINUE_CONFIG);
	paths.push(path.join(agentDir(), CONFIG_FILE_NAME));
	paths.push(path.join(ctx.cwd, ".pi", CONFIG_FILE_NAME));
	return [...new Set(paths)];
}

function normalizeConfigPatch(input: unknown, base: TrackingConfig, source: string, diagnostics: string[]): TrackingConfig {
	if (!isRecord(input)) {
		diagnostics.push(`${source}: expected a JSON object`);
		return base;
	}
	const next: TrackingConfig = { ...base };
	const tracking = isRecord(input.tracking) ? input.tracking : undefined;
	next.enabled = booleanValue(input.enabled) ?? booleanValue(tracking?.enabled) ?? base.enabled;
	next.appendSessionEntries = booleanValue(input.appendSessionEntries) ?? booleanValue(tracking?.appendSessionEntries) ?? base.appendSessionEntries;
	next.log = booleanValue(input.log) ?? booleanValue(tracking?.log) ?? base.log;
	next.maxRecentEvents = Math.max(1, Math.min(100, Math.floor(numberValue(input.maxRecentEvents) ?? numberValue(tracking?.maxRecentEvents) ?? base.maxRecentEvents)));
	return next;
}

export function loadTrackingConfig(ctx: ExtensionContext): LoadedTrackingConfig {
	let config = { ...DEFAULT_TRACKING_CONFIG };
	const loaded: string[] = [];
	const diagnostics: string[] = [];
	for (const configPath of configPaths(ctx)) {
		if (!fs.existsSync(configPath)) continue;
		try {
			const parsed = JSON.parse(fs.readFileSync(configPath, "utf-8")) as unknown;
			config = normalizeConfigPatch(parsed, config, configPath, diagnostics);
			loaded.push(configPath);
		} catch (error) {
			diagnostics.push(`${configPath}: ${error instanceof Error ? error.message : String(error)}`);
		}
	}
	return { config, paths: loaded, diagnostics };
}

export function sessionIdFromContext(ctx: ExtensionContext): string {
	const manager = ctx.sessionManager as unknown as { getSessionId?: () => string } | undefined;
	try {
		const sessionId = manager?.getSessionId?.();
		if (sessionId) return sessionId;
	} catch {
		// Fall through.
	}
	return `process:${process.pid}:${ctx.cwd}`;
}

function nowIso(): string {
	return new Date().toISOString();
}

function shortHash(value: string): string {
	return crypto.createHash("sha256").update(value).digest("hex").slice(0, 16);
}

export function makeTrackingEvent(ctx: ExtensionContext, event: TrackingEventInput): TrackingEvent {
	if (event.kind === "watchdog_answer") {
		const note = typeof event.note === "string" && event.note.trim() ? event.note.trim() : undefined;
		return {
			...event,
			version: 1,
			timestamp: nowIso(),
			sessionId: sessionIdFromContext(ctx),
			repoRoot: ctx.cwd,
			note,
			noteLength: note ? note.length : undefined,
			noteHash: note ? shortHash(note) : undefined,
		};
	}
	return {
		...event,
		version: 1,
		timestamp: nowIso(),
		sessionId: sessionIdFromContext(ctx),
		repoRoot: ctx.cwd,
	};
}

export function appendTrackingLog(event: TrackingEvent): void {
	try {
		const logPath = trackingLogPath(event.sessionId);
		fs.mkdirSync(path.dirname(logPath), { recursive: true });
		fs.appendFileSync(logPath, `${JSON.stringify(logSafeTrackingEvent(event))}\n`);
	} catch {
		// Passive tracking must never affect extension behavior.
	}
}

export function logSafeTrackingEvent(event: TrackingEvent): Record<string, unknown> {
	if (event.kind !== "watchdog_answer") return event as unknown as Record<string, unknown>;
	const { note: _note, ...safe } = event;
	return safe;
}
