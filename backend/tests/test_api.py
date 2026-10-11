import re
import threading
from datetime import date

import pytest


def tx_body(items, patient="Siti Aminah", pay=1_000_000, method="Cash"):
    return {"patient_name": patient, "payment_method": method, "payment": pay,
            "items": [{"product_id": pid, "quantity": q} for pid, q in items]}


# ------------------------- AUTH & ROLE (server-side) -------------------------
def test_health(client):
    assert client.get("/api/health").json()["status"] == "ok"


def test_login_ok_and_wrong_password(client):
    assert client.post("/api/auth/login", json={"username": "owner", "password": "salah"}).status_code == 401
    r = client.post("/api/auth/login", json={"username": "OWNER", "password": "owner-pass-1"})
    assert r.status_code == 200 and r.json()["user"]["role"] == "OWNER"
    assert "password_hash" not in r.text


def test_password_is_hashed(client):
    from app.db import connect
    conn = connect()
    h = conn.execute("SELECT password_hash FROM users WHERE username='owner'").fetchone()[0]
    conn.close()
    assert h.startswith("$2") and "owner-pass-1" not in h


def test_unauthenticated_is_rejected(client):
    for path in ("/api/products", "/api/transactions", "/api/users", "/api/audit-logs", "/api/categories"):
        assert client.get(path).status_code == 401
    assert client.get("/api/products", headers={"Authorization": "Bearer abc"}).status_code == 401


def test_cashier_cannot_do_owner_actions(client, kasir_h, owner_h, pid):
    # buat 1 transaksi untuk dicoba dihapus
    tx = client.post("/api/transactions", headers=kasir_h,
                     json=tx_body([(pid("Konsultasi Dokter"), 1)])).json()
    forbidden = [
        client.post("/api/products", headers=kasir_h, json={"name": "X", "category_id": 1, "sale_price": 1}),
        client.patch(f"/api/products/{pid('Sanmol')}", headers=kasir_h, json={"sale_price": 1}),
        client.get("/api/users", headers=kasir_h),
        client.post("/api/users", headers=kasir_h, json={"username": "hack", "full_name": "Hack", "password": "123456"}),
        client.patch("/api/users/1", headers=kasir_h, json={"full_name": "Hacked"}),
        client.get("/api/audit-logs", headers=kasir_h),
        client.get("/api/reports/summary", headers=kasir_h),
        client.get("/api/reports/export.xlsx", headers=kasir_h),
        client.get("/api/reports/export.pdf", headers=kasir_h),
        client.get("/api/dashboard/owner", headers=kasir_h),
        client.put("/api/settings/numbering", headers=kasir_h, json={"next_sequence": 1}),
        client.get("/api/settings/numbering", headers=kasir_h),
        client.post(f"/api/transactions/{tx['id']}/delete", headers=kasir_h, json={"reason": "coba hapus"}),
        client.post(f"/api/transactions/{tx['id']}/restore", headers=kasir_h),
    ]
    assert [r.status_code for r in forbidden] == [403] * len(forbidden)
    # transaksi masih aktif & sanmol harganya tidak berubah
    assert client.get(f"/api/transactions/{tx['id']}", headers=owner_h).json()["status"] == "COMPLETED"
    assert [p for p in client.get("/api/products?q=Sanmol", headers=owner_h).json()][0]["sale_price"] == 1000


def test_cashier_sees_only_active_products(client, owner_h, kasir_h, pid):
    sid = pid("Sanmol")
    assert client.patch(f"/api/products/{sid}", headers=owner_h, json={"is_active": False}).status_code == 200
    names = [p["name"] for p in client.get("/api/products?include_inactive=true", headers=kasir_h).json()]
    assert "Sanmol" not in names                                    # kasir: include_inactive diabaikan
    assert "Sanmol" in [p["name"] for p in client.get("/api/products?include_inactive=true", headers=owner_h).json()]
    r = client.post("/api/transactions", headers=kasir_h, json=tx_body([(sid, 1)]))
    assert r.status_code == 400                                       # produk nonaktif tidak bisa dijual
    client.patch(f"/api/products/{sid}", headers=owner_h, json={"is_active": True})


def test_owner_manages_cashier_accounts_and_tokens_are_revoked(client, owner_h):
    r = client.post("/api/users", headers=owner_h, json={"username": "baru", "full_name": "Kasir Baru", "password": "abcdef"})
    assert r.status_code == 201 and r.json()["role"] == "KASIR"
    assert client.post("/api/users", headers=owner_h, json={"username": "baru", "full_name": "Dup", "password": "abcdef"}).status_code == 409
    assert client.post("/api/users", headers=owner_h, json={"username": "pendek", "full_name": "Ab", "password": "123"}).status_code == 400
    tok = client.post("/api/auth/login", json={"username": "baru", "password": "abcdef"}).json()["access_token"]
    h = {"Authorization": "Bearer " + tok}
    assert client.get("/api/auth/me", headers=h).status_code == 200
    uid = r.json()["id"]
    client.patch(f"/api/users/{uid}", headers=owner_h, json={"is_active": False})
    assert client.get("/api/auth/me", headers=h).status_code == 401              # token langsung mati
    assert client.post("/api/auth/login", json={"username": "baru", "password": "abcdef"}).status_code == 401
    assert client.patch("/api/users/1", headers=owner_h, json={"full_name": "Xx"}).status_code == 403  # owner tak bisa diubah


def test_change_password_revokes_old_token(client, owner_h):
    client.post("/api/users", headers=owner_h, json={"username": "pw1", "full_name": "Pw Satu", "password": "lama123"})
    h = {"Authorization": "Bearer " + client.post("/api/auth/login", json={"username": "pw1", "password": "lama123"}).json()["access_token"]}
    assert client.post("/api/auth/change-password", headers=h, json={"old_password": "salah", "new_password": "baru1234"}).status_code == 400
    r = client.post("/api/auth/change-password", headers=h, json={"old_password": "lama123", "new_password": "baru1234"})
    assert r.status_code == 200
    assert client.get("/api/auth/me", headers=h).status_code == 401
    assert client.get("/api/auth/me", headers={"Authorization": "Bearer " + r.json()["access_token"]}).status_code == 200


# ------------------------- TRANSAKSI -------------------------
def test_create_transaction_numbers_snapshots_and_doctor(client, kasir_h, owner_h, pid):
    body = tx_body([(pid("Konsultasi Dokter"), 1), (pid("USG 2D"), 1), (pid("Kalnex"), 10)], pay=300000)
    body["doctor_name"] = "dr. Orang Lain"                               # harus diabaikan server
    r = client.post("/api/transactions", headers=kasir_h, json=body)
    assert r.status_code == 201, r.text
    t = r.json()
    assert re.fullmatch(r"\d+/\d{4}", t["transaction_number"])            # format Excel NNN/MMYY
    assert t["subtotal"] == 120000 + 80000 + 75000 == t["total"]
    assert t["payment"] == 300000 and t["change"] == 25000 and t["discount"] == 0
    assert t["doctor_name"] == "dr. Maulia Mardini, SpOG, MARS"
    assert t["cashier_name"] == "Nunung Nurjanah" and t["status"] == "COMPLETED"
    assert t["total_words"] == "Duaratus Tujuhpuluh Lima Ribu Rupiah"
    k = next(i for i in t["items"] if i["product_name"] == "Kalnex")
    assert (k["price"], k["quantity"], k["subtotal"], k["unit"]) == (7500, 10, 75000, "pcs")


def test_transaction_numbers_increase_and_are_unique(client, kasir_h, pid):
    nums = [client.post("/api/transactions", headers=kasir_h, json=tx_body([(pid("Sanmol"), 1)], pay=1000)).json()["transaction_number"]
            for _ in range(3)]
    seqs = [int(n.split("/")[0]) for n in nums]
    assert seqs == sorted(seqs) and len(set(nums)) == 3 and seqs[0] >= 368


def test_payment_validation(client, kasir_h, pid):
    r = client.post("/api/transactions", headers=kasir_h, json=tx_body([(pid("Konsultasi Dokter"), 1)], pay=119999))
    assert r.status_code == 400 and r.json()["detail"] == "Nominal pembayaran belum mencukupi."
    assert client.post("/api/transactions", headers=kasir_h, json=tx_body([(pid("Konsultasi Dokter"), 1)], patient="  ")).status_code in (400, 422)
    assert client.post("/api/transactions", headers=kasir_h, json=tx_body([(pid("Konsultasi Dokter"), 1)], method="Bitcoin")).status_code == 400
    assert client.post("/api/transactions", headers=kasir_h, json={"patient_name": "A B", "items": [], "payment": 1}).status_code == 422
    assert client.post("/api/transactions", headers=kasir_h, json=tx_body([(999999, 1)])).status_code == 400
    dup = {"patient_name": "Ab", "payment": 10 ** 6, "items": [{"product_id": pid("Sanmol"), "quantity": 1}] * 2}
    assert client.post("/api/transactions", headers=kasir_h, json=dup).status_code == 400


def test_cashier_cannot_override_price_except_flexible_items(client, kasir_h, pid):
    body = {"patient_name": "Ny Tes", "payment": 10 ** 7,
            "items": [{"product_id": pid("Konsultasi Dokter"), "quantity": 1, "unit_price": 1}]}
    assert client.post("/api/transactions", headers=kasir_h, json=body).status_code == 403
    body["items"] = [{"product_id": pid("Tindakan Kuretasi"), "quantity": 1, "unit_price": 1730000}]
    r = client.post("/api/transactions", headers=kasir_h, json=body)
    assert r.status_code == 201 and r.json()["total"] == 1730000
    zero = {"patient_name": "Ny Tes", "payment": 10 ** 7, "items": [{"product_id": pid("Lain-lain"), "quantity": 1}]}
    assert client.post("/api/transactions", headers=kasir_h, json=zero).status_code == 400   # harga bebas wajib diisi


def test_old_transactions_keep_snapshot_when_price_changes(client, owner_h, kasir_h, pid):
    sid = pid("Caldece")
    t = client.post("/api/transactions", headers=kasir_h, json=tx_body([(sid, 2)], pay=100000)).json()
    assert t["items"][0]["price"] == 48000
    r = client.patch(f"/api/products/{sid}", headers=owner_h, json={"sale_price": 55000, "name": "Caldece Baru"})
    assert r.status_code == 200 and r.json()["sale_price"] == 55000
    old = client.get(f"/api/transactions/{t['id']}", headers=owner_h).json()
    assert old["items"][0]["price"] == 48000 and old["items"][0]["product_name"] == "Caldece" and old["total"] == 96000
    new = client.post("/api/transactions", headers=kasir_h, json=tx_body([(sid, 1)], pay=100000)).json()
    assert new["items"][0]["price"] == 55000
    logs = client.get("/api/audit-logs?action=UPDATE_PRICE", headers=owner_h).json()["items"]
    assert any("48.000" in l["description"] and "55.000" in l["description"] for l in logs)


def test_concurrent_transactions_get_unique_numbers(client, kasir_h, kasir2_h, pid):
    results, errors = [], []

    def work(h):
        try:
            r = client.post("/api/transactions", headers=h, json=tx_body([(pid("Sanmol"), 1)], pay=1000))
            results.append((r.status_code, r.json().get("transaction_number")))
        except Exception as e:  # pragma: no cover
            errors.append(e)
    threads = [threading.Thread(target=work, args=(kasir_h if i % 2 else kasir2_h,)) for i in range(16)]
    [t.start() for t in threads]; [t.join() for t in threads]
    assert not errors and all(c == 201 for c, _ in results)
    nums = [n for _, n in results]
    assert len(set(nums)) == len(nums) == 16


# ------------------------- SOFT DELETE, LAPORAN, AUDIT -------------------------
def test_soft_delete_excluded_from_reports_but_visible_to_owner(client, owner_h, kasir_h, pid):
    today = date.today().isoformat()
    before = client.get("/api/reports/summary", headers=owner_h).json()
    t = client.post("/api/transactions", headers=kasir_h, json=tx_body([(pid("Papsmear"), 1)], pay=600000)).json()
    mid = client.get("/api/reports/summary", headers=owner_h).json()
    assert mid["total_sales"] == before["total_sales"] + 600000 and mid["transaction_count"] == before["transaction_count"] + 1
    r = client.post(f"/api/transactions/{t['id']}/delete", headers=owner_h, json={"reason": "Kesalahan input"})
    assert r.status_code == 200
    d = r.json()
    assert d["status"] == "DELETED" and d["deleted_by_name"] == "Owner" and d["deletion_reason"] == "Kesalahan input" and d["deleted_at"]
    after = client.get("/api/reports/summary", headers=owner_h).json()
    assert after["total_sales"] == before["total_sales"] and after["transaction_count"] == before["transaction_count"]
    assert after["deleted_count"] >= 1
    dash = client.get("/api/dashboard/owner", headers=owner_h).json()
    assert t["id"] not in [x["id"] for x in dash["recent"]] and t["id"] in [x["id"] for x in dash["deleted"]]
    assert all(c["total"] >= 0 for c in dash["chart"]) and len(dash["chart"]) == 14
    # kasir tidak melihatnya lagi; owner masih bisa
    assert client.get(f"/api/transactions/{t['id']}", headers=kasir_h).status_code == 404
    assert client.get(f"/api/transactions/{t['id']}/receipt", headers=kasir_h).status_code == 404
    assert t["id"] not in [x["id"] for x in client.get("/api/transactions?status=ALL&limit=200", headers=kasir_h).json()["items"]]
    assert client.get(f"/api/transactions/{t['id']}", headers=owner_h).json()["status"] == "DELETED"
    deleted_list = client.get("/api/transactions?status=DELETED", headers=owner_h).json()["items"]
    assert t["id"] in [x["id"] for x in deleted_list]
    assert client.get(f"/api/transactions/{t['id']}/receipt", headers=owner_h).json()["stamp"] == "DIHAPUS OLEH OWNER"
    assert client.post(f"/api/transactions/{t['id']}/delete", headers=owner_h, json={"reason": "lagi"}).status_code == 409
    assert client.post(f"/api/transactions/{t['id']}/delete", headers=owner_h, json={"reason": ""}).status_code == 422
    audit = client.get("/api/audit-logs?action=DELETE_TRANSACTION", headers=owner_h).json()["items"]
    assert any(t["transaction_number"] in a["description"] and "Kesalahan input" in a["description"] for a in audit)
    # pulihkan
    assert client.post(f"/api/transactions/{t['id']}/restore", headers=owner_h).json()["status"] == "COMPLETED"
    back = client.get("/api/reports/summary", headers=owner_h).json()
    assert back["total_sales"] == mid["total_sales"]
    assert today == back["from"]


def test_cashier_history_is_own_only(client, kasir_h, kasir2_h, pid):
    mine = client.post("/api/transactions", headers=kasir_h, json=tx_body([(pid("Sanmol"), 1)], patient="Milik Nunung", pay=1000)).json()
    other = client.post("/api/transactions", headers=kasir2_h, json=tx_body([(pid("Sanmol"), 1)], patient="Milik Dua", pay=1000)).json()
    ids = [x["id"] for x in client.get("/api/transactions?limit=200", headers=kasir_h).json()["items"]]
    assert mine["id"] in ids and other["id"] not in ids
    assert client.get(f"/api/transactions/{other['id']}", headers=kasir_h).status_code == 404
    found = client.get("/api/transactions?q=Nunung", headers=kasir_h).json()["items"]
    assert any(x["patient_name"] == "Milik Nunung" for x in found)
    assert client.get("/api/dashboard/cashier", headers=kasir_h).json()["today_count"] >= 1


def test_audit_log_records_key_events(client, owner_h):
    actions = {a["action"] for a in client.get("/api/audit-logs?limit=200", headers=owner_h).json()["items"]}
    assert {"LOGIN", "CREATE_TRANSACTION", "UPDATE_PRICE", "DELETE_TRANSACTION", "CREATE_USER", "RESTORE_TRANSACTION"} <= actions
    client.post("/api/auth/logout", headers=owner_h)
    assert "LOGOUT" in {a["action"] for a in client.get("/api/audit-logs?limit=200", headers=owner_h).json()["items"]}


def test_owner_can_create_product_and_set_numbering(client, owner_h, kasir_h):
    cats = client.get("/api/categories", headers=owner_h).json()
    assert [c["name"] for c in cats][:3] == ["Obat", "Jasa", "Tindakan"]
    r = client.post("/api/products", headers=owner_h, json={"name": "Vitamin Tes", "category_id": cats[0]["id"], "unit": "pcs", "sale_price": 12500})
    assert r.status_code == 201 and r.json()["icon_name"] == "medicine/vitamin"
    assert client.post("/api/products", headers=owner_h, json={"name": "vitamin tes", "category_id": cats[0]["id"], "sale_price": 1}).status_code == 409
    assert client.put("/api/settings/numbering", headers=owner_h, json={"next_sequence": 900}).json()["next_sequence"] == 900
    t = client.post("/api/transactions", headers=kasir_h, json=tx_body([(r.json()["id"], 1)], pay=20000)).json()
    assert t["transaction_number"].startswith("900/")
    assert client.get("/api/transactions/next-number", headers=kasir_h).json()["number"].startswith("901/")


def test_reports_exports_and_validation(client, owner_h):
    x = client.get("/api/reports/export.xlsx", headers=owner_h)
    assert x.status_code == 200 and x.content[:2] == b"PK"
    p = client.get("/api/reports/export.pdf", headers=owner_h)
    assert p.status_code == 200 and p.content[:4] == b"%PDF"
    assert client.get("/api/reports/summary?from_date=2026-10-10&to_date=2026-10-01", headers=owner_h).status_code == 400
    assert client.get("/api/reports/summary?from_date=2020-01-01&to_date=2026-10-01", headers=owner_h).status_code == 400
    s = client.get("/api/reports/summary", headers=owner_h).json()
    assert s["top_items"] and set(s) >= {"total_sales", "transaction_count", "total_payment", "daily", "by_category"}
