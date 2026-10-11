"""Lapisan database (SQLite, WAL). Satu koneksi per request."""
import secrets
import sqlite3
from datetime import datetime
from typing import Iterator

from . import config

SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE COLLATE NOCASE,
  full_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('OWNER','KASIR')),
  is_active INTEGER NOT NULL DEFAULT 1,
  token_version INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  receipt_label TEXT NOT NULL,
  receipt_order INTEGER NOT NULL,
  sort_order INTEGER NOT NULL,
  icon_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category_id INTEGER NOT NULL REFERENCES categories(id),
  unit TEXT,
  cost_price REAL,
  sale_price INTEGER NOT NULL DEFAULT 0 CHECK (sale_price >= 0),
  price_editable INTEGER NOT NULL DEFAULT 0,
  icon_name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  source TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_products_cat ON products(category_id);
CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_number TEXT NOT NULL UNIQUE,
  sequence_number INTEGER NOT NULL,
  transaction_date TEXT NOT NULL,
  cashier_id INTEGER NOT NULL REFERENCES users(id),
  cashier_name TEXT NOT NULL,
  patient_name TEXT NOT NULL,
  doctor_name TEXT NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'Cash',
  subtotal INTEGER NOT NULL,
  discount INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL,
  payment INTEGER NOT NULL,
  change INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('COMPLETED','DELETED')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  deleted_by INTEGER REFERENCES users(id),
  deleted_by_name TEXT,
  deletion_reason TEXT
);
CREATE INDEX IF NOT EXISTS idx_tx_date ON transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_tx_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_tx_cashier ON transactions(cashier_id);
CREATE TABLE IF NOT EXISTS transaction_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL REFERENCES transactions(id),
  line_no INTEGER NOT NULL,
  product_id INTEGER REFERENCES products(id),
  product_name_snapshot TEXT NOT NULL,
  category_name_snapshot TEXT NOT NULL,
  receipt_label_snapshot TEXT NOT NULL,
  receipt_order_snapshot INTEGER NOT NULL,
  unit_snapshot TEXT,
  price INTEGER NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  subtotal INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_items_tx ON transaction_items(transaction_id);
CREATE TABLE IF NOT EXISTS audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  username TEXT,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  description TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at);
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
"""


def now() -> datetime:
    return datetime.now(config.TZ)


def now_iso() -> str:
    return now().isoformat(timespec="seconds")


def connect() -> sqlite3.Connection:
    config.DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(config.DB_PATH), timeout=15, isolation_level=None,
                           check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA busy_timeout=15000")
    return conn


def init_db() -> None:
    conn = connect()
    try:
        conn.execute("PRAGMA journal_mode=WAL")
        conn.executescript(SCHEMA)
        conn.execute(
            "INSERT OR IGNORE INTO settings(key,value) VALUES('next_sequence',?)",
            (str(config.DEFAULT_NEXT_SEQUENCE),),
        )
    finally:
        conn.close()


def get_db() -> Iterator[sqlite3.Connection]:
    conn = connect()
    try:
        yield conn
    finally:
        conn.close()


def get_setting(conn: sqlite3.Connection, key: str, default: str = "") -> str:
    row = conn.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
    return row["value"] if row else default


def set_setting(conn: sqlite3.Connection, key: str, value: str) -> None:
    conn.execute(
        "INSERT INTO settings(key,value) VALUES(?,?) "
        "ON CONFLICT(key) DO UPDATE SET value=excluded.value",
        (key, value),
    )


def jwt_secret(conn: sqlite3.Connection) -> str:
    if config.JWT_SECRET:
        return config.JWT_SECRET
    secret = get_setting(conn, "jwt_secret")
    if not secret:
        secret = secrets.token_urlsafe(48)
        conn.execute("INSERT OR IGNORE INTO settings(key,value) VALUES('jwt_secret',?)", (secret,))
        secret = get_setting(conn, "jwt_secret")
    return secret


def audit(conn: sqlite3.Connection, user, action: str, entity: str,
          entity_id, description: str) -> None:
    """Catat aktivitas penting. `user` boleh dict/Row dengan id & username, atau None."""
    uid = user["id"] if user is not None else None
    uname = user["username"] if user is not None else None
    conn.execute(
        "INSERT INTO audit_logs(user_id,username,action,entity,entity_id,description,created_at)"
        " VALUES(?,?,?,?,?,?,?)",
        (uid, uname, action, entity, None if entity_id is None else str(entity_id),
         description, now_iso()),
    )
