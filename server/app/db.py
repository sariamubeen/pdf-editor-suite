"""
Simple SQLite user store for pdf-editor-suite.
No passwords — just name + email identification.
"""

import os
import sqlite3
from datetime import datetime

DB_PATH = os.environ.get("DB_PATH", "/app/data/users.db")


def _get_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = _get_db()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
    """)
    conn.commit()
    conn.close()


def get_user_by_email(email):
    conn = _get_db()
    row = conn.execute("SELECT * FROM users WHERE email = ?", (email.lower(),)).fetchone()
    conn.close()
    if row:
        return {"id": row["id"], "name": row["name"], "email": row["email"]}
    return None


def create_user(name, email):
    conn = _get_db()
    conn.execute("INSERT INTO users (name, email) VALUES (?, ?)", (name, email.lower()))
    conn.commit()
    user = conn.execute("SELECT * FROM users WHERE email = ?", (email.lower(),)).fetchone()
    conn.close()
    return {"id": user["id"], "name": user["name"], "email": user["email"]}


def get_user_by_id(user_id):
    conn = _get_db()
    row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()
    if row:
        return {"id": row["id"], "name": row["name"], "email": row["email"]}
    return None
