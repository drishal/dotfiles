#!/usr/bin/env python3
import sqlite3
import json
import os
import sys

def load_messages(db_path, session_id):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT role, content, tool_name, tool_calls,
               reasoning, reasoning_content, timestamp
        FROM messages
        WHERE session_id = ?
        ORDER BY timestamp ASC
        LIMIT 500
    """, (session_id,)).fetchall()

    out = [dict(r) for r in rows]
    print(json.dumps(out))
    conn.close()

if __name__ == '__main__':
    db = os.path.expanduser(os.environ.get('DB', '~/.hermes/state.db'))
    sid = os.environ.get('SID', '')
    load_messages(db, sid)
