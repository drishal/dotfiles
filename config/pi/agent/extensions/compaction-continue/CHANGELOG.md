# Changelog

## 0.1.5

- Added opt-in passive tracking for watchdog detection, nudge, skip, and `watchdog_answer` events.
- Added the `compaction_continue_state` tool plus config/log-path reporting for inspection and debugging.
- Added user/project config loading for passive tracking, with tracking disabled by default unless enabled by config.
- Scoped watchdog completion-marker guidance to active loops so non-loop nudges do not ask agents to emit `<promise>COMPLETE</promise>`.

## 0.1.4

- Added generic stalled-turn watchdog recovery that is not tied to Ralph loops.
- Added a `watchdog_answer` tool so nudge responses can self-check `done: true|false` before continuing or stopping.
- Updated the watchdog prompt to require a tool answer instead of a prose acknowledgement, and to re-nudge when the agent answers `done: false` but still does not continue.

## 0.1.3

- Fixed post-compaction watchdog recovery for assistant turns that stop with `stopReason: "length"` instead of a structured context length error.
- Added regression coverage for length-stopped assistant messages so overflow compactions can trigger a recovery nudge.

## 0.1.2

- Added idle watchdog recovery for stalled Ralph turns where the assistant says it will continue but does not call `ralph_done`.
- Improved compaction recovery so nudges are deferred while Pi is busy and only sent when Pi is idle with no queued messages.
- Tightened recovery prompts to tell the agent to stop when work is already complete instead of inventing more work.
- Updated status/help text to describe watchdog behavior for both compaction and Ralph idle recovery.

## 0.1.1

- Initial public package release for idle compaction continuation.
