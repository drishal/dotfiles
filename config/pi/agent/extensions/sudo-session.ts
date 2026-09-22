/**
 * pi-sudo-session — minimal sudo extension.
 *
 * Inspired by npm:pi-root-grant, but:
 *  - Wraps ONLY the `bash` tool (read/write/edit are left untouched → no conflict
 *    with hashline read/edit tools).
 *  - No duration cap. Once enabled, sudo stays active for the rest of the session
 *    (until `/sudo-off`, `session_shutdown`, or the keepalive detects the creds
 *    are no longer valid).
 *  - A keepalive re-runs `sudo -v` periodically so the sudo timestamp never
 *    expires — this also benefits non-wrapped `sudo` calls (user `!sudo`, etc.).
 *
 * Commands: /sudo, /sudo-off, /sudo-status
 * Tools:    request_sudo, revoke_sudo
 *
 * Security: the password lives only in memory for the session and is wiped on
 * revoke/shutdown. Review before trusting. — MIT.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	createBashToolDefinition,
	ExtensionInputComponent,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { spawn } from "node:child_process";

const STATUS_KEY = "sudo-session";
const KEEPALIVE_INTERVAL_MS = 2 * 60 * 1000; // refresh sudo timestamp well before the typical 5min timeout

interface SudoState {
	active: boolean;
	password?: string;
	keepalive?: ReturnType<typeof setInterval>;
}

interface ToolResult {
	content: Array<{ type: "text"; text: string }>;
	details: Record<string, unknown>;
	isError?: boolean;
}

function textResult(text: string, details: Record<string, unknown> = {}, isError = false): ToolResult {
	return { content: [{ type: "text", text }], details, isError };
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

/** Spawn `sudo -S -p '' <args>` feeding the password (if any) on stdin. */
function sudoSpawn(
	password: string | undefined,
	args: string[],
	timeoutMs = 60_000,
): Promise<{ code: number | null; stdout: string; stderr: string; killed: boolean }> {
	return new Promise((resolve) => {
		const child = spawn("sudo", ["-S", "-p", "", ...args], {
			stdio: ["pipe", "pipe", "pipe"],
		});
		const stdout: Buffer[] = [];
		const stderr: Buffer[] = [];
		let killed = false;
		const timer = setTimeout(() => {
			killed = true;
			child.kill("SIGTERM");
		}, timeoutMs);

		child.stdout.on("data", (c) => stdout.push(Buffer.from(c)));
		child.stderr.on("data", (c) => stderr.push(Buffer.from(c)));
		child.on("close", (code) => {
			clearTimeout(timer);
			resolve({
				code,
				stdout: Buffer.concat(stdout).toString(),
				stderr: Buffer.concat(stderr).toString(),
				killed,
			});
		});
		child.stdin.end(password ? `${password}\n` : "\n");
	});
}

async function validateSudo(password: string | undefined): Promise<boolean> {
	const r = await sudoSpawn(password, ["-v"], 15_000);
	return r.code === 0;
}

/** Masked password dialog. Returns undefined if the user cancels. */
async function promptPassword(ctx: any, reason: string): Promise<string | undefined> {
	return ctx.ui.custom((tui: any, _theme: any, _kb: any, done: (value: string | undefined) => void) => {
		const component: any = new ExtensionInputComponent(
			`sudo password required\n\n${reason}\n\nPassword is masked and sent only to sudo via stdin.`,
			"",
			(value: string) => done(value),
			() => done(undefined),
			{ tui },
		);
		const input = component.input;
		if (input?.render && input?.getValue) {
			input.render = function (width: number): string[] {
				const prompt = "> ";
				const availableWidth = Math.max(0, width - prompt.length);
				const count = Math.min(this.getValue().length, Math.max(0, availableWidth - 1));
				const bullets = "•".repeat(count);
				const cursor = "\x1b[7m \x1b[27m";
				const padding = " ".repeat(Math.max(0, availableWidth - count - 1));
				return [prompt + bullets + cursor + padding];
			};
		}
		return component;
	});
}

/** Bash operations that run every command under sudo while a session is active. */
function createSudoBashOperations(password?: string) {
	return {
		exec(
			command: string,
			cwd: string,
			options: {
				onData: (data: Buffer) => void;
				signal?: AbortSignal;
				timeout?: number;
				env?: NodeJS.ProcessEnv;
			},
		): Promise<{ exitCode: number | null }> {
			return new Promise((resolve, reject) => {
				const child = spawn(
					"sudo",
					["-S", "-p", "", "bash", "-lc", `cd ${shellQuote(cwd)} && ${command}`],
					{ cwd: "/", env: options.env, stdio: ["pipe", "pipe", "pipe"] },
				);
				let timedOut = false;
				const timeoutHandle =
					options.timeout && options.timeout > 0
						? setTimeout(() => {
								timedOut = true;
								child.kill("SIGTERM");
							}, options.timeout * 1000)
						: undefined;
				const onAbort = () => child.kill("SIGTERM");
				if (options.signal?.aborted) onAbort();
				else options.signal?.addEventListener("abort", onAbort, { once: true });

				child.stdout.on("data", options.onData);
				child.stderr.on("data", options.onData);
				child.on("error", (error) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					options.signal?.removeEventListener("abort", onAbort);
					reject(error);
				});
				child.on("close", (code) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					options.signal?.removeEventListener("abort", onAbort);
					if (options.signal?.aborted) reject(new Error("aborted"));
					else if (timedOut) reject(new Error(`timeout:${options.timeout}`));
					else resolve({ exitCode: code });
				});
				child.stdin.end(password ? `${password}\n` : "\n");
			});
		},
	};
}

export default function sudoSession(pi: ExtensionAPI) {
	let state: SudoState = { active: false };

	function clearStatus(ctx?: { ui?: { setStatus?: (key: string, value?: string) => void } }) {
		ctx?.ui?.setStatus?.(STATUS_KEY, undefined);
	}

	function revoke(
		ctx?: {
			ui?: {
				setStatus?: (key: string, value?: string) => void;
				notify?: (message: string, type?: "info" | "warning" | "error") => void;
			};
		},
		reason = "Sudo session revoked",
	) {
		const wasActive = state.active;
		if (state.keepalive) clearInterval(state.keepalive);
		state.password = "";
		state.active = false;
		state.keepalive = undefined;
		clearStatus(ctx);
		if (wasActive) void pi.exec("sudo", ["-k"], { timeout: 5_000 }).catch(() => undefined);
		ctx?.ui?.notify?.(reason, "info");
	}

	function updateStatus(ctx: { ui: { setStatus: (key: string, value?: string) => void } }) {
		ctx.ui.setStatus(STATUS_KEY, state.active ? "SUDO active" : undefined);
	}

	/** Keep the sudo timestamp fresh and detect revoked/changed credentials. */
	function startKeepalive(ctx: any) {
		if (state.keepalive) clearInterval(state.keepalive);
		state.keepalive = setInterval(() => {
			void validateSudo(state.password).then((ok) => {
				if (ok) return;
				revoke(ctx, "Sudo session ended (credentials no longer valid)");
			});
		}, KEEPALIVE_INTERVAL_MS);
		// Don't keep the event loop alive solely for the keepalive.
		if (state.keepalive && typeof (state.keepalive as any).unref === "function") {
			(state.keepalive as any).unref();
		}
	}

	async function enableSudo(reason: string, ctx: any): Promise<ToolResult> {
		if (state.active) return textResult("Sudo session already active.", { active: true });

		const ok = await ctx.ui.confirm(
			"Enable sudo for this session?",
			`Reason: ${reason}\n\nThe agent's bash tool will run commands as root via sudo until you run /sudo-off or end the session. No duration cap.`,
		);
		if (!ok) return textResult("Sudo request denied by user.", { active: false });

		// Try cached/NOPASSWD first.
		const probe = await pi.exec("sudo", ["-n", "-v"], { timeout: 10_000 });
		let password: string | undefined;
		if (probe.code !== 0) {
			const pw = await promptPassword(ctx, reason);
			if (!pw) return textResult("Sudo request cancelled.", { active: false });
			const valid = await validateSudo(pw);
			if (!valid) {
				return textResult("sudo authentication failed.", { active: false, error: true }, true);
			}
			password = pw;
		}

		state.password = password;
		state.active = true;
		startKeepalive(ctx);
		updateStatus(ctx);
		ctx.ui.notify("Sudo session enabled for the rest of the session.", "warning");
		return textResult("Sudo session enabled. bash commands now run as root until /sudo-off or session end.", {
			active: true,
		});
	}

	// --- Commands ---

	pi.registerCommand("sudo", {
		description: "Enable a session-persistent sudo grant (no duration cap). Usage: /sudo [reason]",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("Sudo grant requires interactive UI", "error");
				return;
			}
			const reason = args.trim() || "User invoked /sudo";
			const result = await enableSudo(reason, ctx);
			if (result.isError) ctx.ui.notify(result.content[0].text, "error");
		},
	});

	pi.registerCommand("sudo-off", {
		description: "Revoke the session sudo grant and clear the in-memory password",
		handler: async (_args, ctx) => {
			revoke(ctx, "Sudo session revoked by user");
		},
	});

	pi.registerCommand("sudo-status", {
		description: "Show whether the session sudo grant is active",
		handler: async (_args, ctx) => {
			if (!state.active) {
				ctx.ui.notify("Sudo session inactive", "info");
				return;
			}
			updateStatus(ctx);
			ctx.ui.notify("Sudo session active", "warning");
		},
	});

	// --- Tools (so the agent can request sudo when a task needs it) ---

	pi.registerTool({
		name: "request_sudo",
		label: "Request Sudo",
		description:
			"Ask the user to enable a session-persistent sudo grant so bash commands run as root. Use only when a task genuinely requires root. No duration cap; persists until /sudo-off or session end.",
		parameters: Type.Object({
			reason: Type.String({ description: "Why root access is needed" }),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			if (!ctx.hasUI) return textResult("Cannot request sudo without UI.", { active: false }, true);
			return enableSudo(params.reason, ctx);
		},
	});

	pi.registerTool({
		name: "revoke_sudo",
		label: "Revoke Sudo",
		description: "Revoke the session sudo grant immediately and clear the in-memory password.",
		parameters: Type.Object({
			reason: Type.Optional(Type.String({ description: "Why sudo is no longer needed" })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const wasActive = state.active;
			revoke(ctx, params.reason ? `Sudo revoked: ${params.reason}` : "Sudo revoked by agent");
			return textResult(
				wasActive ? "Sudo revoked. In-memory password cleared." : "Sudo was already inactive.",
				{ revoked: wasActive },
			);
		},
	});

	// --- Wrap ONLY the bash tool. read/write/edit are left untouched. ---

	const bashTool = createBashToolDefinition(process.cwd());
	pi.registerTool({
		...bashTool,
		description: `${bashTool.description} Runs as root via sudo while a session sudo grant is active (see /sudo).`,
		async execute(toolCallId, params, signal, onUpdate, ctx) {
			if (!state.active) {
				return createBashToolDefinition(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx);
			}
			updateStatus(ctx);
			return createBashToolDefinition(ctx.cwd, {
				operations: createSudoBashOperations(state.password),
			}).execute(toolCallId, params, signal, onUpdate, ctx);
		},
	});

	// --- Cleanup on shutdown ---

	pi.on("session_shutdown", async (_event, ctx) => {
		revoke(ctx, "Sudo session revoked at session shutdown");
	});
}
