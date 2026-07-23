from __future__ import annotations

import os
import subprocess


def _report(state: str, **_kwargs) -> None:
    if not os.environ.get("TMUX") or not os.environ.get("TMUX_PANE"):
        return
    try:
        subprocess.Popen(
            ["@tmuxAgentState@", "hermes", state],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        pass


def register(ctx):
    ctx.register_hook("on_session_start", lambda **kwargs: _report("done", **kwargs))
    ctx.register_hook("pre_llm_call", lambda **kwargs: _report("working", **kwargs))
    ctx.register_hook("pre_api_request", lambda **kwargs: _report("working", **kwargs))
    ctx.register_hook("pre_tool_call", lambda **kwargs: _report("working", **kwargs))
    ctx.register_hook("post_tool_call", lambda **kwargs: _report("working", **kwargs))
    ctx.register_hook("pre_approval_request", lambda **kwargs: _report("ask", **kwargs))
    ctx.register_hook("post_approval_response", lambda **kwargs: _report("working", **kwargs))
    ctx.register_hook("post_llm_call", lambda **kwargs: _report("done", **kwargs))
    ctx.register_hook("on_session_end", lambda **kwargs: _report("done", **kwargs))
