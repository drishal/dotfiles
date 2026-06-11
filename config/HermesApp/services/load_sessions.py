#!/usr/bin/env python3
import sqlite3
import json
import os
import re
import sys

def load_sessions(db_path, limit=30):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
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
    """, (limit,)).fetchall()

    out = []
    for r in rows:
        d = dict(r)
        title = d.get('title') or 'New chat'
        title = re.sub(r'\s+', ' ', title).strip()[:64]
        out.append({
            'id': d.get('id', ''),
            'title': title,
            'model': d.get('model', ''),
            'started_at': d.get('started_at', 0),
            'message_count': d.get('message_count', 0)
        })

    print(json.dumps(out))
    conn.close()

if __name__ == '__main__':
    db = os.path.expanduser(os.environ.get('DB', '~/.hermes/state.db'))
    limit = int(os.environ.get('LIMIT', '30'))
    load_sessions(db, limit)
