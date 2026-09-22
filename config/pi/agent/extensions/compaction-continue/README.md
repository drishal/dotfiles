# pi-compaction-continue

Auto-sends a watchdog nudge when Pi stops while there may still be obvious work to resume.

Use it for long sessions where a compaction or a stalled continuation turn can leave Pi idle even though the next useful action may be to continue.

## Install

```bash
pi install npm:@badliveware/pi-compaction-continue
```

No external services, credentials, or extra CLIs are required.

## How it works

The extension watches two low-risk recovery cases and sends an automated watchdog nudge only when Pi is idle. The nudge tells the agent that it is not a new user request, to self-check completion through a dedicated tool call, and then either continue real work or stop.

Recovery cases:

- **Idle compaction:** after a compaction, Pi is idle, no messages are queued, and either the compaction followed a context overflow or the current session branch contains an unresolved/resumable Ralph prompt. A stale active `.ralph/*.state.json` file alone is not enough.
- **Stalled continuation turn:** the assistant ends while saying it will continue or proceed, or it answers the watchdog self-check with `done: false` but still does not continue actual work.

It snapshots/analyzes the branch before compaction and suppresses nudges when Ralph already advanced with `ralph_done`. It does nothing while tools are running or messages are already queued, because that means there is no idle gap to recover. Generic stall recovery is capped to three consecutive automatic nudges until a real tool call, a non-continuation assistant reply, or a substantive new user request resets the streak. The footer status shows `watchdog:on` or `watchdog:off`.

The watchdog prompt tells the agent not to acknowledge the nudge in prose. Instead it must call `watchdog_answer` first, then stop if the task is already done or continue from the next concrete step. The prompt still reminds looped agents that `<promise>COMPLETE</promise>` belongs only to genuinely finished loops.

## Passive tracking

Passive tracking is **off by default**. When enabled, the extension records structured events for:

- watchdog recovery candidates it detected
- watchdog nudges it actually sent
- nudges it skipped and why
- `watchdog_answer` tool calls

Tracking can write session entries, a JSONL log, or both.

User-global config path:

```text
~/.pi/agent/compaction-continue.json
```

Project overlay path:

```text
.pi/compaction-continue.json
```

Example:

```json
{
  "enabled": true,
  "appendSessionEntries": true,
  "log": true,
  "maxRecentEvents": 20
}
```

Environment overrides:

- `PI_COMPACTION_CONTINUE_CONFIG` — extra config file to load first
- `PI_COMPACTION_CONTINUE_LOG` — force one JSONL log path
- `PI_COMPACTION_CONTINUE_DIR` — change the default log directory

Use the read-only `compaction_continue_state` tool to inspect the effective tracking status, loaded config paths, log path, and recent in-memory events.

## Commands

| Command | What it does |
| --- | --- |
| `/compaction-continue` | Show status, active loop detection, current assistant-stall streak, and whether passive tracking is enabled. |
| `/compaction-continue on` | Enable auto-continue. |
| `/compaction-continue off` | Disable auto-continue. |
| `/ralph-compact-watchdog` | Compatibility alias for older local setups. |
