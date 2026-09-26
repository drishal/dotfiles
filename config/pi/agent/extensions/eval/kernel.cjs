"use strict";
/**
 * JavaScript kernel for the eval tool — one Node process per session.
 *
 * Semantics are the Node REPL's: top-level await, declarations that persist
 * across cells (including ones made under await), require()/import() resolved
 * from the working directory, built-in modules as globals (fs, path, …), and
 * the value of the last expression.
 *
 * Two paths share one global scope:
 *   - cells without `await` run through vm.runInThisContext with
 *     breakOnSigint, so Ctrl+C stops even a synchronous `while (true) {}`;
 *   - cells with `await` go through Node's REPL evaluator for its top-level
 *     await rewriting. (Its own breakEvalOnSigint is broken in Node 24 — the
 *     process dies on the next SIGINT — so it is off; an await cell stops at
 *     its next await instead.)
 *
 * Protocol: commands arrive as JSON lines on stdin, `{ id, code }`. The kernel
 * answers on fd 3 with `{ type: "done", id, ok, value?, error? }`. Anything the
 * cell prints goes to the real stdout/stderr, which the host captures; a
 * sentinel written to both after each cell tells the host the streams are
 * drained.
 */
const fs = require("node:fs");
const readline = require("node:readline");
const repl = require("node:repl");
const util = require("node:util");
const vm = require("node:vm");
const { PassThrough } = require("node:stream");

const sentinel = (id) => `\u0000EVAL_DONE:${id}\u0000`;
const send = (msg) => fs.writeSync(3, `${JSON.stringify(msg)}\n`);

// The REPL writes errors (not results — those come back through the
// callback) to its output stream as "Uncaught …". Runtime errors and
// SyntaxErrors never reach the eval callback, so this is how they surface.
const replOut = new PassThrough();
const server = repl.start({
	input: new PassThrough(),
	output: replOut,
	prompt: "",
	terminal: false,
	useColors: false,
	useGlobal: true,
	ignoreUndefined: true,
	breakEvalOnSigint: false,
	preview: false,
});

let current; // { id, errorText?, timer? }

function finish(id, result) {
	if (!current || current.id !== id) return;
	clearTimeout(current.timer);
	current = undefined;
	fs.writeSync(1, sentinel(id));
	fs.writeSync(2, sentinel(id));
	send({ type: "done", id, ...result });
}

replOut.on("data", (chunk) => {
	const text = chunk.toString();
	if (!current || !text.trim()) return;
	if (current.errorText === undefined && !/^\s*Uncaught\b/.test(text)) return;
	// Collect the whole message (it can arrive in pieces), then finish.
	current.errorText = (current.errorText ?? "") + text;
	clearTimeout(current.timer);
	const { id } = current;
	current.timer = setTimeout(() => {
		finish(id, { ok: false, error: cleanError(current?.errorText ?? "Error") });
	}, 25);
});

// Ctrl+C while a cell awaits (breakOnSigint only covers synchronous code,
// and suspends this handler while it is active).
function onSigint() {
	if (current) finish(current.id, { ok: false, error: "Interrupted (pending async work may still complete)" });
}
/**
 * (Re-)install the SIGINT listener. After a REPL evaluation with
 * breakEvalOnSigint, Node's native SIGINT handler is gone even though the JS
 * listener is still registered — the next Ctrl+C kills the process (Node 24).
 * Dropping and re-adding the listener makes Node install the handler again.
 */
function armSigint() {
	process.removeListener("SIGINT", onSigint);
	process.on("SIGINT", onSigint);
}
armSigint();

/** Node's REPL and this kernel are not the user's code: drop their frames. */
const INTERNAL_FRAME = /^\s+at .*(\bnode:[a-z_/]+:\d+|sigintHandlersWrap|kernel\.cjs)/;
const cleanError = (text) =>
	text
		.replace(/^\s*Uncaught:?\s*/, "")
		.split("\n")
		.filter((line) => !INTERNAL_FRAME.test(line))
		.join("\n")
		.trim();

/**
 * Let a cell be re-run: top-level (column 0) `const`/`let` become `var`, and
 * `class Name` becomes `var Name = class Name`, all of which may be declared
 * again. Without this, running `const x = …` twice fails with "Identifier 'x'
 * has already been declared" — the usual agent loop of fixing a cell and
 * running it again.
 */
const relaxDeclarations = (code) =>
	code.replace(/^(const|let)(\s+)/gm, "var$2").replace(/^class\s+([A-Za-z_$][\w$]*)/gm, "var $1 = class $1");

const show = (value) => util.inspect(value, { depth: 4, maxArrayLength: 100, maxStringLength: 20_000, breakLength: 100 });
const errorText = (err) =>
	String(err?.message ?? "").startsWith("Script execution was interrupted")
		? "Interrupted (Ctrl+C)"
		: cleanError(err instanceof Error ? util.inspect(err) : `Uncaught ${util.inspect(err)}`);

/** A cell with no top-level await: plain script, interruptible. */
function runScript(id, code) {
	current = { id };
	let value;
	try {
		value = vm.runInThisContext(relaxDeclarations(code), { filename: `cell-${id}`, breakOnSigint: true });
	} catch (err) {
		armSigint();
		finish(id, { ok: false, error: errorText(err) });
		return;
	}
	armSigint();
	// A returned promise (fetch(…).then(…)) is awaited, like an await cell.
	if (value && typeof value.then === "function") {
		value.then(
			(v) => {
				if (v !== undefined) globalThis._ = v;
				finish(id, { ok: true, value: v === undefined ? undefined : show(v) });
			},
			(err) => finish(id, { ok: false, error: errorText(err) }),
		);
		return;
	}
	if (value !== undefined) globalThis._ = value;
	finish(id, { ok: true, value: value === undefined ? undefined : show(value) });
}

function run(id, code) {
	if (!/\bawait\b/.test(code)) return runScript(id, code);
	current = { id };
	server.eval(relaxDeclarations(code), server.context, `cell-${id}`, (err, value) => {
		if (!current || current.id !== id || current.errorText !== undefined) return;
		if (err) {
			const message = err instanceof repl.Recoverable ? "SyntaxError: unexpected end of input" : cleanError(util.inspect(err));
			finish(id, { ok: false, error: message });
			return;
		}
		finish(id, { ok: true, value: value === undefined ? undefined : show(value) });
	});
	armSigint(); // the synchronous part is over; a later Ctrl+C hits onSigint
}

const commands = readline.createInterface({ input: process.stdin });
// pi went away (or disposed the kernel): do not linger.
commands.on("close", () => process.exit(0));
commands.on("line", (line) => {
	let msg;
	try {
		msg = JSON.parse(line);
	} catch {
		return;
	}
	if (msg && typeof msg.code === "string") run(msg.id, msg.code);
});

send({ type: "ready", runtime: `node ${process.version}` });
