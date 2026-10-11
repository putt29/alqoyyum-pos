"""Kategori, produk, dan pengaturan klinik."""
import sqlite3
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException

from . import config
from .db import audit, get_db, get_setting, now_iso, set_setting
from .deps import current_user, require_owner
from .icons import normalize_icon
from .schemas import NumberingIn, ProductIn, ProductPatch

router = APIRouter(prefix="/api")


def product_out(r) -> dict:
    return {"id": r["id"], "name": r["name"], "category_id": r["category_id"],
            "category_name": r["category_name"], "unit": r["unit"],
            "cost_price": r["cost_price"], "sale_price": r["sale_price"],
            "price_editable": bool(r["price_editable"]), "icon_name": r["icon_name"],
            "is_active": bool(r["is_active"]), "created_at": r["created_at"],
            "updated_at": r["updated_at"]}


_PSELECT = ("SELECT p.*, c.name AS category_name FROM products p "
            "JOIN categories c ON c.id=p.category_id ")


@router.get("/categories")
def categories(user=Depends(current_user), conn: sqlite3.Connection = Depends(get_db)):
    rows = conn.execute("SELECT * FROM categories ORDER BY sort_order").fetchall()
    return [{"id": r["id"], "name": r["name"], "receipt_label": r["receipt_label"],
             "icon_name": r["icon_name"]} for r in rows]


@router.get("/products")
def products(q: str = "", category_id: Optional[int] = None, include_inactive: bool = False,
             user=Depends(current_user), conn: sqlite3.Connection = Depends(get_db)):
    where, args = [], []
    if user["role"] != "OWNER" or not include_inactive:
        where.append("p.is_active=1")          # kasir hanya melihat produk aktif
    if category_id is not None:
        where.append("p.category_id=?"); args.append(category_id)
    if q.strip():
        where.append("p.name LIKE ? ESCAPE '\\'")
        args.append("%" + q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%")
    sql = _PSELECT + ("WHERE " + " AND ".join(where) + " " if where else "") + \
        "ORDER BY c.sort_order, p.name COLLATE NOCASE"
    return [product_out(r) for r in conn.execute(sql, args).fetchall()]


def _category(conn, category_id: int):
    row = conn.execute("SELECT * FROM categories WHERE id=?", (category_id,)).fetchone()
    if row is None:
        raise HTTPException(400, "Kategori tidak ditemukan.")
    return row


@router.post("/products", status_code=201)
def create_product(body: ProductIn, owner=Depends(require_owner),
                   conn: sqlite3.Connection = Depends(get_db)):
    cat = _category(conn, body.category_id)
    name = " ".join(body.name.split())
    if conn.execute("SELECT 1 FROM products WHERE lower(name)=lower(?) AND category_id=?",
                    (name, cat["id"])).fetchone():
        raise HTTPException(409, "Produk dengan nama tersebut sudah ada di kategori ini.")
    ts = now_iso()
    cur = conn.execute(
        "INSERT INTO products(name,category_id,unit,cost_price,sale_price,price_editable,icon_name,"
        "is_active,source,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)",
        (name, cat["id"], (body.unit or None), body.cost_price, body.sale_price,
         1 if body.price_editable else 0, normalize_icon(body.icon_name, name, cat["name"]),
         1 if body.is_active else 0, "manual", ts, ts))
    audit(conn, owner, "CREATE_PRODUCT", "product", cur.lastrowid,
          f"Produk '{name}' ({cat['name']}) dibuat, harga Rp{body.sale_price:,}".replace(",", "."))
    return product_out(conn.execute(_PSELECT + "WHERE p.id=?", (cur.lastrowid,)).fetchone())


@router.patch("/products/{product_id}")
def update_product(product_id: int, body: ProductPatch, owner=Depends(require_owner),
                   conn: sqlite3.Connection = Depends(get_db)):
    row = conn.execute(_PSELECT + "WHERE p.id=?", (product_id,)).fetchone()
    if row is None:
        raise HTTPException(404, "Produk tidak ditemukan.")
    sets, vals, changed = [], [], []
    cat_name = row["category_name"]
    if body.category_id is not None and body.category_id != row["category_id"]:
        cat = _category(conn, body.category_id)
        sets.append("category_id=?"); vals.append(cat["id"]); changed.append(f"kategori→{cat['name']}")
        cat_name = cat["name"]
    if body.name is not None:
        name = " ".join(body.name.split())
        if name != row["name"]:
            sets.append("name=?"); vals.append(name); changed.append(f"nama→{name}")
    if body.clear_unit:
        sets.append("unit=NULL"); changed.append("satuan dikosongkan")
    elif body.unit is not None:
        sets.append("unit=?"); vals.append(body.unit.strip() or None); changed.append(f"satuan→{body.unit}")
    if body.clear_cost:
        sets.append("cost_price=NULL"); changed.append("harga modal dikosongkan")
    elif body.cost_price is not None:
        sets.append("cost_price=?"); vals.append(body.cost_price); changed.append("harga modal")
    if body.price_editable is not None and bool(row["price_editable"]) != body.price_editable:
        sets.append("price_editable=?"); vals.append(1 if body.price_editable else 0)
        changed.append("harga bebas " + ("aktif" if body.price_editable else "nonaktif"))
    if body.icon_name is not None:
        sets.append("icon_name=?"); vals.append(normalize_icon(body.icon_name, body.name or row["name"], cat_name))
        changed.append("icon")
    if body.is_active is not None and bool(row["is_active"]) != body.is_active:
        sets.append("is_active=?"); vals.append(1 if body.is_active else 0)
        changed.append("diaktifkan" if body.is_active else "dinonaktifkan")
    price_changed = body.sale_price is not None and body.sale_price != row["sale_price"]
    if price_changed:
        sets.append("sale_price=?"); vals.append(body.sale_price)
    if sets:
        sets.append("updated_at=?"); vals.append(now_iso())
        conn.execute(f"UPDATE products SET {', '.join(sets)} WHERE id=?", (*vals, product_id))
        if price_changed:
            audit(conn, owner, "UPDATE_PRICE", "product", product_id,
                  f"Harga '{row['name']}': Rp{row['sale_price']:,} → Rp{body.sale_price:,}".replace(",", "."))
        if changed:
            audit(conn, owner, "UPDATE_PRODUCT", "product", product_id,
                  f"Produk '{row['name']}': " + ", ".join(changed))
    return product_out(conn.execute(_PSELECT + "WHERE p.id=?", (product_id,)).fetchone())


# ---------------- Pengaturan klinik ----------------
@router.get("/settings/clinic")
def clinic(user=Depends(current_user)):
    return {"name": config.CLINIC_NAME, "address": config.CLINIC_ADDRESS,
            "phone": config.CLINIC_PHONE, "whatsapp": config.CLINIC_WHATSAPP,
            "sipd": config.CLINIC_SIPD, "doctor": config.DOCTOR_FULL,
            "payment_methods": list(config.PAYMENT_METHODS),
            "max_items": config.MAX_ITEMS_PER_TX}


@router.get("/settings/numbering")
def get_numbering(owner=Depends(require_owner), conn: sqlite3.Connection = Depends(get_db)):
    return {"next_sequence": int(get_setting(conn, "next_sequence", "1"))}


@router.put("/settings/numbering")
def put_numbering(body: NumberingIn, owner=Depends(require_owner),
                  conn: sqlite3.Connection = Depends(get_db)):
    old = get_setting(conn, "next_sequence", "1")
    set_setting(conn, "next_sequence", str(body.next_sequence))
    audit(conn, owner, "UPDATE_SETTING", "setting", "next_sequence",
          f"Nomor kwitansi berikutnya: {old} → {body.next_sequence}")
    return {"next_sequence": body.next_sequence}
