"""Pembuat dokumen struk (isi/teks) mengikuti kwitansi Excel.

Server menyusun *isi* struk (teks, urutan, format angka & tanggal). Aplikasi
Flutter hanya menggambar dokumen ini dengan SATU template yang dipakai bersama
untuk preview, print dan PNG.
"""
import re
from datetime import datetime
from typing import Optional

from . import config
from .terbilang import terbilang_rupiah

MONTHS_ID = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli",
             "Agustus", "September", "Oktober", "November", "Desember"]

DEFAULT_PATIENT_TITLE = "Ny."   # Excel: ": Ny." (bisa diganti: Tn., Nn., An., Drg., ...)

_CANON = {"ny": "Ny.", "nn": "Nn.", "tn": "Tn.", "an": "An.", "by": "By.", "bpk": "Bpk.",
          "sdr": "Sdr.", "sdri": "Sdri.", "drg": "Drg.", "dr": "Dr.", "hj": "Hj.",
          "ibu": "Ibu", "bapak": "Bapak", "bayi": "Bayi", "nyonya": "Nyonya",
          "nona": "Nona", "tuan": "Tuan"}
_TITLE_RE = re.compile(
    r"^\s*(?:(ny|nn|tn|bpk|sdr|sdri|drg|hj)(?:\.\s*|\s+)|(an|by|dr)\.\s*|"
    r"(ibu|bapak|bayi|nyonya|nona|tuan)\s+)(\S.*)$", re.I)


def clean_name(raw: str) -> str:
    return re.sub(r"\s+", " ", (raw or "").strip())


def split_title(patient_name: str) -> tuple:
    """'Siti Aminah' -> ('Ny.', 'Siti Aminah'); 'Tn. Samijo' -> ('Tn.', 'Samijo')."""
    name = clean_name(patient_name)
    m = _TITLE_RE.match(name)
    if m:
        key = (m.group(1) or m.group(2) or m.group(3)).lower()
        return _CANON[key], m.group(4).strip()
    return DEFAULT_PATIENT_TITLE, name


def format_amount(n: int) -> str:
    """Format akuntansi Excel: 120000 -> '120.000,00' (separator gaya Indonesia)."""
    return f"{n:,}".replace(",", ".") + ",00"


def format_date_id(dt: datetime) -> str:
    return f"{dt.day:02d} {MONTHS_ID[dt.month - 1]} {dt.year}"


def number_line(transaction_number: str) -> str:
    return f"NO : {transaction_number}"


def build_receipt(tx, items, joined_terbilang: bool = True) -> dict:
    """tx: baris transactions; items: baris transaction_items (urut line_no)."""
    dt = datetime.fromisoformat(tx["transaction_date"])
    title, name = split_title(tx["patient_name"])
    groups = {}
    for it in sorted(items, key=lambda r: r["line_no"]):
        label = it["receipt_label_snapshot"]
        key = (it["receipt_order_snapshot"], label)
        unit = it["unit_snapshot"]
        qty: Optional[int]
        if unit:
            qty, unit_txt = it["quantity"], unit
        elif it["quantity"] > 1:
            qty, unit_txt = it["quantity"], "x"
        else:
            qty, unit_txt = None, None
        groups.setdefault(key, {"label": label, "lines": []})["lines"].append({
            "name": it["product_name_snapshot"],
            "qty": qty,
            "unit": unit_txt,
            "amount": it["subtotal"],
            "amount_text": format_amount(it["subtotal"]),
        })
    ordered = [groups[k] for k in sorted(groups)]
    line_count = sum(len(g["lines"]) for g in ordered)
    doctor_title, doctor_name = config.DOCTOR_TITLE, config.DOCTOR_NAME
    return {
        "paper": {"name": "B5", "width_mm": 176, "height_mm": 250},
        "clinic": {
            "name": config.CLINIC_NAME,
            "address": config.CLINIC_ADDRESS,
            "sipd_line": config.CLINIC_SIPD_LINE,
            "phone_line": config.CLINIC_PHONE_LINE,
        },
        "title": "BUKTI PEMBAYARAN",
        "number_line": number_line(tx["transaction_number"]),
        "date_text": format_date_id(dt),
        "received_from": {"label": "Diterima dari", "title": title, "name": name},
        "patient": {"label": "Nama Pasien", "title": title, "name": name},
        "doctor": {"label": "Nama Dokter", "title": doctor_title, "name": doctor_name},
        "for_payment_label": "Untuk Pembayaran",
        "groups": ordered,
        "line_count": line_count,
        "underline_last": line_count >= 2,
        "currency": "Rp",
        "total_label": "Total Pembayaran",
        "total": tx["total"],
        "total_text": format_amount(tx["total"]),
        "payment_method_label": "Cara Pembayaran",
        "payment_method": tx["payment_method"],
        "words_label": "Terbilang",
        "words": terbilang_rupiah(tx["total"], joined_terbilang),
        "signature": {"label": "Diterima oleh:", "name": tx["cashier_name"]},
        "payment": tx["payment"],
        "change": tx["change"],
        "status": tx["status"],
        "stamp": "DIHAPUS OLEH OWNER" if tx["status"] == "DELETED" else None,
    }
