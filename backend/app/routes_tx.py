"""Transaksi: buat, daftar, detail, struk, hapus (soft delete), pulihkan."""
import sqlite3
from datetime import date, datetime, time as dtime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException

from . import config
from .db import audit, get_db, get_setting, now, now_iso, set_setting
from .deps import current_user, require_owner
from .receipt import build_receipt, clean_name
from .schemas import TxCreate, TxDeleteIn
from .terbilang import terbilang_rupiah

router = APIRouter(prefix="/api")


def day_start(d: date) -> str:
    return datetime.combine(d, dtime.min, tzinfo=config.TZ).isoformat(timespec="seconds")


def range_bounds(d_from: date, d_to: date):
    return day_start(d_from), day_start(d_to + timedelta(days=1))


def rp(n: int) -> str:
    return "Rp" + f"{n:,}".replace(",", ".")


def tx_summary(r) -> dict:
    return {"id": r["id"], "transaction_number": r["transaction_number"],
            "transaction_date": r["transaction_date"], "patient_name": r["patient_name"],
            "cashier_name": r["cashier_name"], "payment_method": r["payment_method"],
            "total": r["total"], "status": r["status"],
            "item_count": r["item_count"] if "item_count" in r.keys() else None,
            "deleted_at": r["deleted_at"], "deleted_by_name": r["deleted_by_name"],
            "deletion_reason": r["deletion_reason"]}


def tx_detail(conn, tx_id: int) -> dict:
    r = conn.execute("SELECT * FROM transactions WHERE id=?", (tx_id,)).fetchone()
    items = conn.execute("SELECT * FROM transaction_items WHERE transaction_id=? ORDER BY line_no",
                         (tx_id,)).fetchall()
    d = {k: r[k] for k in r.keys()}
    d["total_words"] = terbilang_rupiah(r["total"])
    d["items"] = [{"id": i["id"], "product_id": i["product_id"],
                   "product_name": i["product_name_snapshot"],
                   "category_name": i["category_name_snapshot"], "unit": i["unit_snapshot"],
                   "price": i["price"], "quantity": i["quantity"], "subtotal": i["subtotal"]}
                  for i in items]
    return d


def load_for(conn, user, tx_id: int):
    """Owner: semua (termasuk dihapus). Kasir: hanya miliknya & belum dihapus."""
    r = conn.execute("SELECT * FROM transactions WHERE id=?", (tx_id,)).fetchone()
    if r is None or (user["role"] != "OWNER" and
                     (r["cashier_id"] != user["id"] or r["status"] != "COMPLETED")):
        raise HTTPException(404, "Transaksi tidak ditemukan.")
    return r


def _next_number(conn, dt: datetime):
    seq = int(get_setting(conn, "next_sequence", str(config.DEFAULT_NEXT_SEQUENCE)))
    while True:
        number = f"{seq}/{dt:%m%y}"       # format Excel: NO : 367/1026
        if not conn.execute("SELECT 1 FROM transactions WHERE transaction_number=?", (number,)).fetchone():
            return seq, number
        seq += 1


@router.get("/transactions/next-number")
def next_number(user=Depends(current_user), conn: sqlite3.Connection = Depends(get_db)):
    seq, number = _next_number(conn, now())
    return {"sequence": seq, "number": number}


@router.post("/transactions", status_code=201)
def create_transaction(body: TxCreate, user=Depends(current_user),
                       conn: sqlite3.Connection = Depends(get_db)):
    patient = clean_name(body.patient_name)
    if len(patient) < 2:
        raise HTTPException(400, "Nama pasien wajib diisi.")
    if body.payment_method not in config.PAYMENT_METHODS:
        raise HTTPException(400, "Cara pembayaran tidak valid.")
    ids = [i.product_id for i in body.items]
    if len(set(ids)) != len(ids):
        raise HTTPException(400, "Item duplikat dalam satu transaksi.")
    dt = now()
    conn.execute("BEGIN IMMEDIATE")
    try:
        marks = ",".join("?" * len(ids))
        prods = {p["id"]: p for p in conn.execute(
            f"SELECT p.*, c.name AS category_name, c.receipt_label, c.receipt_order "
            f"FROM products p JOIN categories c ON c.id=p.category_id WHERE p.id IN ({marks})", ids)}
        lines, subtotal = [], 0
        for n, it in enumerate(body.items, start=1):
            p = prods.get(it.product_id)
            if p is None or not p["is_active"]:
                raise HTTPException(400, "Ada produk yang tidak tersedia atau sudah nonaktif.")
            if it.unit_price is not None and it.unit_price != p["sale_price"]:
                if not p["price_editable"]:
                    raise HTTPException(403, f"Harga '{p['name']}' tidak dapat diubah saat transaksi.")
                price = it.unit_price
            else:
                price = p["sale_price"]
            if price <= 0:
                raise HTTPException(400, f"Harga '{p['name']}' harus diisi (lebih dari 0).")
            sub = price * it.quantity
            subtotal += sub
            lines.append((n, p, price, it.quantity, sub))
        total = subtotal                      # Excel tidak memiliki diskon
        if total <= 0:
            raise HTTPException(400, "Total transaksi harus lebih dari 0.")
        if body.payment < total:
            raise HTTPException(400, "Nominal pembayaran belum mencukupi.")
        change = body.payment - total
        seq, number = _next_number(conn, dt)
        set_setting(conn, "next_sequence", str(seq + 1))
        ts = dt.isoformat(timespec="seconds")
        cur = conn.execute(
            "INSERT INTO transactions(transaction_number,sequence_number,transaction_date,cashier_id,"
            "cashier_name,patient_name,doctor_name,payment_method,subtotal,discount,total,payment,"
            "change,status,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,0,?,?,?,'COMPLETED',?,?)",
            (number, seq, ts, user["id"], user["full_name"], patient, config.DOCTOR_FULL,
             body.payment_method, subtotal, total, body.payment, change, ts, ts))
        tx_id = cur.lastrowid
        for n, p, price, qty, sub in lines:
            conn.execute(
                "INSERT INTO transaction_items(transaction_id,line_no,product_id,product_name_snapshot,"
                "category_name_snapshot,receipt_label_snapshot,receipt_order_snapshot,unit_snapshot,"
                "price,quantity,subtotal) VALUES(?,?,?,?,?,?,?,?,?,?,?)",
                (tx_id, n, p["id"], p["name"], p["category_name"], p["receipt_label"],
                 p["receipt_order"], p["unit"], price, qty, sub))
        audit(conn, user, "CREATE_TRANSACTION", "transaction", tx_id,
              f"Transaksi {number} dibuat untuk {patient}, total {rp(total)}")
        conn.execute("COMMIT")
    except BaseException:
        conn.execute("ROLLBACK")
        raise
    return tx_detail(conn, tx_id)


@router.get("/transactions")
def list_transactions(q: str = "", status: str = "COMPLETED", from_date: Optional[date] = None,
                      to_date: Optional[date] = None, cashier_id: Optional[int] = None,
                      limit: int = 50, offset: int = 0, user=Depends(current_user),
                      conn: sqlite3.Connection = Depends(get_db)):
    limit = max(1, min(limit, 200)); offset = max(0, offset)
    where, args = [], []
    if user["role"] == "OWNER":
        if status in ("COMPLETED", "DELETED"):
            where.append("t.status=?"); args.append(status)
        if cashier_id is not None:
            where.append("t.cashier_id=?"); args.append(cashier_id)
    else:                                      # kasir: hanya miliknya, tidak termasuk yang dihapus
        where += ["t.cashier_id=?", "t.status='COMPLETED'"]; args.append(user["id"])
    if from_date or to_date:
        start, end = range_bounds(from_date or to_date, to_date or from_date)
        where += ["t.transaction_date>=?", "t.transaction_date<?"]; args += [start, end]
    if q.strip():
        like = "%" + q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"
        where.append("(t.patient_name LIKE ? ESCAPE '\\' OR t.transaction_number LIKE ? ESCAPE '\\')")
        args += [like, like]
    w = ("WHERE " + " AND ".join(where)) if where else ""
    total = conn.execute(f"SELECT COUNT(*) FROM transactions t {w}", args).fetchone()[0]
    rows = conn.execute(
        f"SELECT t.*, (SELECT COUNT(*) FROM transaction_items i WHERE i.transaction_id=t.id) AS item_count "
        f"FROM transactions t {w} ORDER BY t.transaction_date DESC, t.id DESC LIMIT ? OFFSET ?",
        (*args, limit, offset)).fetchall()
    return {"total": total, "items": [tx_summary(r) for r in rows]}


@router.get("/transactions/{tx_id}")
def get_transaction(tx_id: int, user=Depends(current_user), conn: sqlite3.Connection = Depends(get_db)):
    load_for(conn, user, tx_id)
    return tx_detail(conn, tx_id)


@router.get("/transactions/{tx_id}/receipt")
def get_receipt(tx_id: int, user=Depends(current_user), conn: sqlite3.Connection = Depends(get_db)):
    tx = load_for(conn, user, tx_id)
    items = conn.execute("SELECT * FROM transaction_items WHERE transaction_id=? ORDER BY line_no",
                         (tx_id,)).fetchall()
    return build_receipt(tx, items)


@router.post("/transactions/{tx_id}/delete")
def delete_transaction(tx_id: int, body: TxDeleteIn, owner=Depends(require_owner),
                       conn: sqlite3.Connection = Depends(get_db)):
    """Soft delete: data tetap ada untuk audit, tapi tidak masuk laporan aktif."""
    tx = load_for(conn, owner, tx_id)
    if tx["status"] != "COMPLETED":
        raise HTTPException(409, "Transaksi sudah dihapus.")
    ts = now_iso()
    conn.execute("UPDATE transactions SET status='DELETED', deleted_at=?, deleted_by=?, "
                 "deleted_by_name=?, deletion_reason=?, updated_at=? WHERE id=?",
                 (ts, owner["id"], owner["full_name"], body.reason.strip(), ts, tx_id))
    audit(conn, owner, "DELETE_TRANSACTION", "transaction", tx_id,
          f"Transaksi {tx['transaction_number']} (Pasien: {tx['patient_name']}, {rp(tx['total'])}) "
          f"dihapus oleh OWNER. Alasan: {body.reason.strip()}")
    return tx_detail(conn, tx_id)


@router.post("/transactions/{tx_id}/restore")
def restore_transaction(tx_id: int, owner=Depends(require_owner),
                        conn: sqlite3.Connection = Depends(get_db)):
    tx = load_for(conn, owner, tx_id)
    if tx["status"] != "DELETED":
        raise HTTPException(409, "Transaksi tidak dalam status dihapus.")
    conn.execute("UPDATE transactions SET status='COMPLETED', deleted_at=NULL, deleted_by=NULL, "
                 "deleted_by_name=NULL, deletion_reason=NULL, updated_at=? WHERE id=?",
                 (now_iso(), tx_id))
    audit(conn, owner, "RESTORE_TRANSACTION", "transaction", tx_id,
          f"Transaksi {tx['transaction_number']} dipulihkan oleh OWNER")
    return tx_detail(conn, tx_id)
