"""SQLite reads against the Hermes state.db.

Folds in what used to be load_sessions.py / load_messages.py (run as python3
subprocesses by the old QML service) — now plain in-process queries returning
render-ready dicts for the QML ListModels.
"""
from __future__ import annotations

import json
import os
import re
import sqlite3


def _connect(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(os.path.expanduser(db_path))
    conn.row_factory = sqlite3.Row
    return conn


def load_sessions(db_path: str, limit: int = 30) -> list[dict]:
    """Recent sessions, shaped for the sidebar ListModel."""
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT s.id,
                COALESCE(
                    NULLIF(NULLIF(TRIM(s.title), ''), 'Untitled'),
                    NULLIF(TRIM((
                        SELECT m.content FROM messages m
                        WHERE m.session_id = s.id
                          AND m.role = 'user'
                          AND COALESCE(TRIM(m.content), '') != ''
                        ORDER BY m.timestamp ASC LIMIT 1
                    )), '')
                ) AS title,
                s.model,
                s.started_at,
                s.message_count
            FROM sessions s
            WHERE s.message_count > 0
              AND COALESCE(s.source, '') != 'acp'
            ORDER BY s.started_at DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()

    out = []
    for r in rows:
        d = dict(r)
        title = d.get("title") or "New chat"
        title = re.sub(r"\s+", " ", title).strip()[:64]
        out.append(
            {
                "sessionId": str(d.get("id") or ""),
                "title": title,
                "modelName": str(d.get("model") or ""),
                "startedAt": float(d.get("started_at") or 0),
                "messageCount": int(d.get("message_count") or 0),
            }
        )
    return out


def load_messages(db_path: str, session_id: str) -> list[dict]:
    """Persisted messages for a session, expanded into the chat row dicts the
    UI renders (thinking / content / tool_call / tool_result)."""
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT role, content, tool_name, tool_calls,
                   reasoning, reasoning_content, timestamp
            FROM messages
            WHERE session_id = ?
            ORDER BY timestamp ASC
            LIMIT 500
            """,
            (session_id,),
        ).fetchall()

    out: list[dict] = []
    for raw in rows:
        m = dict(raw)
        role = m.get("role") or "assistant"
        ts = float(m.get("timestamp") or 0)

        if role == "tool":
            out.append(
                _row(
                    "tool_result",
                    content=m.get("content") or "",
                    tool=m.get("tool_name") or "tool",
                    toolStatus="completed",
                    timestamp=ts,
                    expanded=False,
                )
            )
            continue

        msg_type = "user" if role == "user" else "assistant"

        reasoning = m.get("reasoning") or m.get("reasoning_content") or ""
        if reasoning and role == "assistant":
            out.append(
                _row("thinking", content=str(reasoning)[:500], timestamp=ts - 0.001)
            )

        content = m.get("content") or ""
        if content:
            out.append(_row(msg_type, content=content, timestamp=ts))

        if m.get("tool_calls") and role == "assistant":
            try:
                calls = json.loads(m["tool_calls"])
            except (ValueError, TypeError):
                calls = []
            for call in calls:
                fn = (call or {}).get("function") or {}
                out.append(
                    _row(
                        "tool_call",
                        tool=fn.get("name") or m.get("tool_name") or "tool",
                        toolPreview=fn.get("arguments") or "",
                        toolStatus="completed",
                        timestamp=ts + 0.0001,
                    )
                )
    return out


def _row(msg_type: str, **kw) -> dict:
    """A chat row with all roles defaulted, so the ListModel sees stable keys."""
    row = {
        "type": msg_type,
        "content": "",
        "tool": "",
        "toolPreview": "",
        "toolStatus": "",
        "toolDuration": 0,
        "isStreaming": False,
        "timestamp": 0,
        # Disclosure state for the collapsible cards (thinking / tool_call /
        # tool_result). Must exist as a role from creation — toggling it via
        # ListModel.setProperty only re-evaluates delegate bindings for roles
        # that were present when the row was appended.
        "expanded": False,
    }
    row.update(kw)
    return row
