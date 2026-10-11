"""Seed data awal: kategori + produk dari Excel (seed/products.json) + akun Owner.

  python -m app.seed                       # buat Owner (password acak ditampilkan sekali)
  python -m app.seed --owner-password XXXX # tentukan password Owner
  python -m app.seed --demo-cashier        # tambah akun kasir demo (kasir / kasir123)
"""
import argparse
import json
import os
import secrets
import sys

from . import config
from .db import audit, connect, init_db, now_iso
from .icons import normalize_icon
from .security import hash_password, password_problem


def seed_catalog(conn) -> dict:
    data = json.loads((config.SEED_DIR / "products.json").read_text(encoding="utf-8"))
    ts = now_iso()
    cats = {}
    for c in data["categories"]:
        conn.execute(
            "INSERT OR IGNORE INTO categories(name,receipt_label,receipt_order,sort_order,icon_name,"
            "created_at,updated_at) VALUES(?,?,?,?,?,?,?)",
            (c["name"], c["receipt_label"], c["receipt_order"], c["sort_order"], c["icon_name"], ts, ts))
        cats[c["name"]] = conn.execute("SELECT id FROM categories WHERE name=?", (c["name"],)).fetchone()["id"]
    added = 0
    conn.execute("BEGIN")
    try:
        for p in data["products"]:
            if conn.execute("SELECT 1 FROM products WHERE lower(name)=lower(?) AND category_id=?",
                            (p["name"], cats[p["category"]])).fetchone():
                continue
            conn.execute(
                "INSERT INTO products(name,category_id,unit,cost_price,sale_price,price_editable,icon_name,"
                "is_active,source,created_at,updated_at) VALUES(?,?,?,?,?,?,?,1,?,?,?)",
                (p["name"], cats[p["category"]], p.get("unit"), p.get("cost_price"), p["sale_price"],
                 1 if p.get("price_editable") else 0,
                 normalize_icon(p.get("icon_name"), p["name"], p["category"]), p.get("source"), ts, ts))
            added += 1
        conn.execute("COMMIT")
    except BaseException:
        conn.execute("ROLLBACK"); raise
    return {"categories": len(cats), "products_added": added}


def ensure_user(conn, username, full_name, password, role) -> bool:
    if conn.execute("SELECT 1 FROM users WHERE username=?", (username,)).fetchone():
        return False
    ts = now_iso()
    cur = conn.execute(
        "INSERT INTO users(username,full_name,password_hash,role,is_active,created_at,updated_at) "
        "VALUES(?,?,?,?,1,?,?)", (username, full_name, hash_password(password), role, ts, ts))
    audit(conn, None, "SEED_USER", "user", cur.lastrowid, f"Akun {role} '{username}' dibuat oleh seed")
    return True


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner-username", default="owner")
    ap.add_argument("--owner-name", default="Owner")
    ap.add_argument("--owner-password", default=os.environ.get("OWNER_PASSWORD", ""))
    ap.add_argument("--demo-cashier", action="store_true")
    ap.add_argument("--no-products", action="store_true")
    a = ap.parse_args(argv)
    init_db()
    conn = connect()
    try:
        if not a.no_products:
            print("Katalog:", seed_catalog(conn))
        pw, generated = a.owner_password, False
        if not pw:
            pw, generated = secrets.token_urlsafe(9), True
        problem = password_problem(pw)
        if problem:
            print("Password Owner tidak valid:", problem); return 2
        if ensure_user(conn, a.owner_username, a.owner_name, pw, "OWNER"):
            print(f"Akun Owner dibuat -> username: {a.owner_username}  password: {pw}"
                  + ("  (SIMPAN, hanya ditampilkan sekali)" if generated else ""))
        else:
            print("Akun Owner sudah ada (tidak diubah).")
        if a.demo_cashier and ensure_user(conn, "kasir", "Kasir Demo", "kasir123", "KASIR"):
            print("Akun demo dibuat -> username: kasir  password: kasir123  (HAPUS/NONAKTIFKAN di produksi)")
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
