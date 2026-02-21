"""SQLite cache for quiet hours and idempotency."""
from __future__ import annotations

import sqlite3
import time
from pathlib import Path


def init_db(db_path: str) -> None:
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(db_path) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS pending (
                id TEXT PRIMARY KEY,
                payload TEXT NOT NULL,
                created_at INTEGER NOT NULL
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS sent (
                id TEXT PRIMARY KEY,
                sent_at INTEGER NOT NULL
            )
            """
        )
        conn.commit()


def already_sent(db_path: str, message_id: str) -> bool:
    with sqlite3.connect(db_path) as conn:
        row = conn.execute("SELECT 1 FROM sent WHERE id = ?", (message_id,)).fetchone()
        return row is not None


def mark_sent(db_path: str, message_id: str) -> None:
    with sqlite3.connect(db_path) as conn:
        conn.execute("INSERT OR REPLACE INTO sent (id, sent_at) VALUES (?, ?)", (message_id, int(time.time())))
        conn.commit()


def enqueue(db_path: str, message_id: str, payload: str) -> None:
    with sqlite3.connect(db_path) as conn:
        conn.execute(
            "INSERT OR REPLACE INTO pending (id, payload, created_at) VALUES (?, ?, ?)",
            (message_id, payload, int(time.time())),
        )
        conn.commit()


def dequeue_all(db_path: str) -> list[tuple[str, str]]:
    with sqlite3.connect(db_path) as conn:
        rows = conn.execute("SELECT id, payload FROM pending ORDER BY created_at ASC").fetchall()
        conn.execute("DELETE FROM pending")
        conn.commit()
    return rows
