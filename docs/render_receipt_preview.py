#!/usr/bin/env python3
"""Simulasi tata letak struk B5 (704x1000) dengan konstanta yang SAMA dengan lib/receipt/receipt_view.dart.
Hanya untuk pratinjau desain (bukan render Flutter). Data diambil dari backend/app/receipt.py."""
import sys
from datetime import datetime
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "backend"))
from app.receipt import build_receipt  # noqa: E402

FONT = "/usr/share/fonts/truetype/crosextra/Carlito-Regular.ttf"
FONTB = "/usr/share/fonts/truetype/crosextra/Carlito-Bold.ttf"
W, H = 704, 1000
MX, MT = 32, 34
CW = W - 2 * MX
PT = 1.229
S = CW / 694
A, B, C, D, E, F, G = [x * S for x in (85, 64, 47, 64, 64, 215, 155)]
ROWH = 15.75 * PT


def fnt(pt, bold=False):
    return ImageFont.truetype(FONTB if bold else FONT, pt * PT)


def render(doc, out):
    im = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(im)
    x0 = MX
    y = MT

    def text(x, ymid, s, pt, bold=False, anchor="lm"):
        d.text((x, ymid), s, font=fnt(pt, bold), fill="black", anchor=anchor)

    def lh(pt):
        return pt * PT * 1.12

    # header
    logo = Image.open(ROOT / "mobile/assets/images/logo_mark.png").convert("RGBA")
    logo.thumbnail((500, 64), Image.LANCZOS)
    im.paste(logo, (int(x0 + 10), int(y + 4)), logo)
    lines = [(doc["clinic"]["name"], 14, True), (doc["clinic"]["address"], 10.5, False),
             (doc["clinic"]["sipd_line"], 10.5, False), (doc["clinic"]["phone_line"], 10.5, False)]
    total_h = sum(lh(p) for _, p, _ in lines)
    yy = y + (74 - total_h) / 2
    for s, p, b in lines:
        text(x0 + CW / 2, yy + lh(p) / 2, s, p, b, "mm")
        yy += lh(p)
    y += 74
    y += 2; d.rectangle((x0, y, x0 + CW, y + 1.4), fill="black"); y += 1.4 + 2
    d.rectangle((x0, y, x0 + CW, y + 1.4), fill="black"); y += 1.4 + 2
    text(x0 + CW / 2, y + lh(14) / 2, doc["title"], 14, True, "mm"); y += lh(14)
    text(x0 + CW / 2, y + lh(12) / 2, doc["number_line"], 12, False, "mm"); y += lh(12)
    y += 4.5 * PT

    def field(p, trailing=None):
        nonlocal y
        h = max(ROWH, lh(12))
        text(x0, y + h / 2, p["label"], 12)
        text(x0 + A + B, y + h / 2, f": {p['title']}", 12)
        text(x0 + A + B + max(C, d.textlength(f": {p['title']}", font=fnt(12))), y + h / 2, p["name"], 12)
        if trailing:
            text(x0 + CW, y + h / 2, trailing, 12, anchor="rm")
        y += h

    field(doc["received_from"], doc["date_text"]); field(doc["patient"]); field(doc["doctor"])
    text(x0, y + ROWH / 2, doc["for_payment_label"], 12); y += ROWH

    def amount(xr_left, ymid, s, pt, bold=False, underline=False):
        text(xr_left, ymid, doc["currency"], pt, bold)
        text(xr_left + G, ymid, s, pt, bold, "rm")
        if underline:
            d.line((xr_left, ymid + ROWH / 2 - 1, xr_left + G, ymid + ROWH / 2 - 1), fill="black", width=1)

    total_lines = sum(len(g["lines"]) for g in doc["groups"])
    idx = 0
    for g in doc["groups"]:
        for i, ln in enumerate(g["lines"]):
            idx += 1
            ym = y + ROWH / 2
            if i == 0:
                text(x0, ym, g["label"], 11); text(x0 + A, ym, ":", 11, anchor="rm")
            text(x0 + A + 4, ym, ln["name"], 11)
            if ln["qty"] is not None:
                text(x0 + A + B + C + D + E, ym, str(ln["qty"]), 11, anchor="rm")
                text(x0 + A + B + C + D + E + 4, ym, ln["unit"] or "", 11)
            amount(x0 + CW - G, ym, ln["amount_text"], 11, underline=doc["underline_last"] and idx == total_lines)
            y += ROWH
    y += ROWH
    ym = y + ROWH / 2
    text(x0, ym, doc["total_label"], 12, True); amount(x0 + CW - G, ym, doc["total_text"], 12, True); y += ROWH
    y += ROWH
    for label, val, bold in ((doc["payment_method_label"], doc["payment_method"], False), (doc["words_label"], doc["words"], True)):
        ym = y + ROWH / 2
        text(x0, ym, label, 12); text(x0 + A + B + C / 2, ym, ":", 12, True, "mm"); text(x0 + A + B + C, ym, val, 12, bold)
        y += ROWH
    y += 4
    xs = x0 + CW - G
    text(xs, y + lh(12) / 2, doc["signature"]["label"], 12); y += lh(12) + 3 * ROWH
    text(xs, y + lh(12) / 2, doc["signature"]["name"], 12)
    im.save(out)
    return im


def sample_doc():
    cats = {"Jasa": ("Jasa", 1), "Tindakan": ("Jasa", 1), "Obat": ("Obat", 4), "BHP": ("BHP", 5)}
    rows = [("Konsultasi Dokter", "Jasa", None, 1, 120000), ("USG 2D", "Jasa", None, 1, 80000),
            ("Irigasi Vagina", "Tindakan", None, 1, 275000), ("Kalnex", "Obat", "pcs", 10, 7500),
            ("Zoltin", "Obat", "pcs", 5, 25000), ("Cefixime", "Obat", "pcs", 6, 7000),
            ("Kasa", "BHP", "pcs", 1, 10000), ("Underpads", "BHP", "pcs", 1, 10000), ("Pembalut", "BHP", "pcs", 1, 2000)]
    items = [{"line_no": i + 1, "product_name_snapshot": n, "category_name_snapshot": c,
              "receipt_label_snapshot": cats[c][0], "receipt_order_snapshot": cats[c][1], "unit_snapshot": u,
              "price": p, "quantity": q, "subtotal": p * q} for i, (n, c, u, q, p) in enumerate(rows)]
    total = sum(i["subtotal"] for i in items)
    tx = {"transaction_number": "368/1026", "transaction_date": "2026-10-09T10:15:00+07:00",
          "patient_name": "Yayuk Novita Dewi", "payment_method": "Cash", "total": total, "payment": total,
          "change": 0, "cashier_name": "Nunung Nurjanah", "status": "COMPLETED"}
    return build_receipt(tx, items)


if __name__ == "__main__":
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "docs" / "preview-struk-B5.png"
    render(sample_doc(), out)
    print("ok", out)
