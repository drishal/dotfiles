"""Python kernel for the eval tool — one process per session.

Plain CPython, no IPython required, so it behaves the same on every machine:

- one namespace shared by every cell (variables, imports, functions persist);
- the value of a trailing expression is returned (and bound to ``_``);
- top-level ``await`` works (one event loop for the whole session);
- ``!cmd`` lines run a shell command, ``%pip install …`` installs into this
  interpreter;
- tracebacks show only the cell's own frames.

Protocol: commands arrive as JSON lines on stdin, ``{"id": n, "code": "…"}``.
The kernel answers on fd 3 with ``{"type": "done", "id", "ok", "value"?,
"error"?}``. Output goes to the real stdout/stderr (so subprocesses stream
too); a sentinel written to both after each cell tells the host they are
drained. SIGINT raises KeyboardInterrupt inside the running cell.
"""
import ast
import asyncio
import inspect
import json
import linecache
import os
import pprint
import re
import shlex
import subprocess
import sys
import traceback

PROTO = os.fdopen(3, "w", buffering=1, encoding="utf-8")
RUNNER = os.path.abspath(__file__)

# Line-buffered, so output streams to the host while a cell runs.
for stream in (sys.stdout, sys.stderr):
    try:
        stream.reconfigure(line_buffering=True, errors="backslashreplace")
    except Exception:
        pass

NS = {"__name__": "__main__", "__builtins__": __builtins__}
LOOP = asyncio.new_event_loop()
asyncio.set_event_loop(LOOP)


def send(msg):
    PROTO.write(json.dumps(msg) + "\n")
    PROTO.flush()


def _sh(cmd):
    """`!cmd` — run through the shell, output straight to the cell's stdout.
    Returns nothing (a trailing `!cmd` must not echo `0`); a failure says so."""
    sys.stdout.flush()
    sys.stderr.flush()
    code = subprocess.run(cmd, shell=True).returncode
    if code:
        print(f"(exit {code})", file=sys.stderr)


def _pip(args):
    """`%pip …` — pip for *this* interpreter, like IPython's %pip."""
    sys.stdout.flush()
    code = subprocess.run([sys.executable, "-m", "pip", *shlex.split(args)]).returncode
    if code:
        print(f"(pip exit {code})", file=sys.stderr)


NS["__eval_sh__"] = _sh
NS["__eval_pip__"] = _pip

SHELL_LINE = re.compile(r"^(\s*)!(.+)$")
PIP_LINE = re.compile(r"^(\s*)%pip\s+(.*)$")


def translate(code):
    """Rewrite `!cmd` and `%pip …` lines into calls; leave everything else."""
    out = []
    for line in code.split("\n"):
        m = SHELL_LINE.match(line)
        if m and not line.lstrip().startswith("!="):
            out.append(f"{m.group(1)}__eval_sh__({json.dumps(m.group(2))})")
            continue
        m = PIP_LINE.match(line)
        if m:
            out.append(f"{m.group(1)}__eval_pip__({json.dumps(m.group(2))})")
            continue
        out.append(line)
    return "\n".join(out)


def await_if_needed(value):
    return LOOP.run_until_complete(value) if inspect.iscoroutine(value) else value


def show(value):
    text = pprint.pformat(value, width=100, compact=True, sort_dicts=False)
    return text if len(text) <= 20000 else text[:20000] + " …"


def format_error(exc):
    """Traceback from the cell's first frame on — never the runner's own frames
    or the parser's (a SyntaxError shows only the offending line)."""
    if isinstance(exc, SyntaxError):
        return "".join(traceback.format_exception_only(exc)).rstrip()
    te = traceback.TracebackException.from_exception(exc)
    frames = list(te.stack)
    first = next((i for i, f in enumerate(frames) if f.filename.startswith("<cell-")), 0)
    te.stack = traceback.StackSummary.from_list(
        [f for f in frames[first:] if os.path.abspath(f.filename) != RUNNER]
    )
    return "".join(te.format()).rstrip()


def run(cell_id, code):
    filename = f"<cell-{cell_id}>"
    source = translate(code)
    linecache.cache[filename] = (len(source), None, source.splitlines(True), filename)
    flags = ast.PyCF_ALLOW_TOP_LEVEL_AWAIT
    tree = ast.parse(source, filename, "exec")
    tail = None
    if tree.body and isinstance(tree.body[-1], ast.Expr):
        tail = ast.Expression(tree.body.pop().value)
    await_if_needed(eval(compile(tree, filename, "exec", flags=flags), NS))
    if tail is None:
        return None
    value = await_if_needed(eval(compile(tail, filename, "eval", flags=flags), NS))
    if value is None:
        return None
    NS["_"] = value
    return show(value)


def finish(cell_id, result):
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.flush()
        except Exception:
            pass
    marker = f"\0EVAL_DONE:{cell_id}\0".encode()
    os.write(1, marker)
    os.write(2, marker)
    send({"type": "done", "id": cell_id, **result})


def main():
    send({"type": "ready", "runtime": f"python {sys.version.split()[0]} ({sys.executable})"})
    while True:
        try:
            line = sys.stdin.readline()
        except KeyboardInterrupt:
            continue  # a stray interrupt between cells
        if not line:
            break
        try:
            msg = json.loads(line)
        except ValueError:
            continue
        cell_id = msg.get("id")
        try:
            value = run(cell_id, msg.get("code", ""))
            finish(cell_id, {"ok": True, "value": value})
        except KeyboardInterrupt:
            finish(cell_id, {"ok": False, "error": "KeyboardInterrupt (cell interrupted)"})
        except SystemExit as exc:
            finish(cell_id, {"ok": False, "error": f"SystemExit({exc.code}) — the kernel keeps running"})
        except BaseException as exc:  # noqa: BLE001 — report every user error
            finish(cell_id, {"ok": False, "error": format_error(exc)})


if __name__ == "__main__":
    main()
