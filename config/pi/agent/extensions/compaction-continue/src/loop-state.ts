import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionContext, SessionEntry } from "@mariozechner/pi-coding-agent";
import { assistantStoppedForContextLimit } from "./analysis.ts";

type RalphStatus = "active" | "paused" | "completed";

export interface RalphState {
	name: string;
	taskFile: string;
	iteration: number;
	maxIterations: number;
	status?: RalphStatus;
	active?: boolean;
}

function ralphDir(ctx: ExtensionContext): string {
	return path.resolve(ctx.cwd, ".ralph");
}

function stateStatus(state: RalphState): RalphStatus {
	return state.status ?? (state.active ? "active" : "paused");
}

function readState(filePath: string): RalphState | undefined {
	try {
		const parsed = JSON.parse(fs.readFileSync(filePath, "utf-8")) as Partial<RalphState>;
		if (!parsed.name || !parsed.taskFile) return undefined;
		return {
			name: parsed.name,
			taskFile: parsed.taskFile,
			iteration: Number.isFinite(parsed.iteration) ? Number(parsed.iteration) : 0,
			maxIterations: Number.isFinite(parsed.maxIterations) ? Number(parsed.maxIterations) : 0,
			status: parsed.status,
			active: parsed.active,
		};
	} catch {
		return undefined;
	}
}

export function findMostRecentActiveLoop(ctx: ExtensionContext): RalphState | undefined {
	const dir = ralphDir(ctx);
	if (!fs.existsSync(dir)) return undefined;

	const candidates: Array<{ state: RalphState; mtimeMs: number }> = [];
	for (const file of fs.readdirSync(dir)) {
		if (!file.endsWith(".state.json")) continue;
		const filePath = path.join(dir, file);
		const state = readState(filePath);
		if (!state || stateStatus(state) !== "active") continue;

		let mtimeMs = 0;
		try {
			mtimeMs = fs.statSync(filePath).mtimeMs;
		} catch {
			// Keep a deterministic fallback if stat fails.
		}
		candidates.push({ state, mtimeMs });
	}

	candidates.sort((a, b) => b.mtimeMs - a.mtimeMs);
	return candidates[0]?.state;
}

export function latestLeafCompactionId(ctx: ExtensionContext): string | undefined {
	const branch = ctx.sessionManager.getBranch();
	const leaf = branch[branch.length - 1] as { type?: string; id?: string } | undefined;
	return leaf?.type === "compaction" ? leaf.id : undefined;
}

export function isOverflowCompaction(ctx: ExtensionContext, compactionId: string): boolean {
	const compaction = ctx.sessionManager.getEntry(compactionId) as { parentId?: string | null } | undefined;
	const parent = compaction?.parentId ? (ctx.sessionManager.getEntry(compaction.parentId) as { type?: string; message?: unknown } | undefined) : undefined;
	return parent?.type === "message" && assistantStoppedForContextLimit(parent.message);
}

export function branchBeforeCompaction(ctx: ExtensionContext, compactionId: string): SessionEntry[] {
	const compaction = ctx.sessionManager.getEntry(compactionId) as { parentId?: string | null } | undefined;
	return compaction?.parentId ? ctx.sessionManager.getBranch(compaction.parentId) : ctx.sessionManager.getBranch();
}

export function messageRole(message: unknown): string | undefined {
	return typeof message === "object" && message !== null && "role" in message && typeof (message as { role?: unknown }).role === "string"
		? ((message as { role: string }).role)
		: undefined;
}
