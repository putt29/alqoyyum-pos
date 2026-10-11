#!/usr/bin/env python3
"""Membuat ikon SVG lokal (flat, minimal, tanpa teks) -> assets/icons/<folder>/<nama>.svg
dan lib/core/icon_registry.dart. Daftar nama harus sama dengan backend/app/icons.py."""
from pathlib import Path

N, L, M, W = "#0B1957", "#D1E8FF", "#9ECCFA", "#FFFFFF"
HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" stroke="%s" '
        'stroke-width="3" stroke-linecap="round" stroke-linejoin="round">' % N)

def f(c): return f'fill="{c}"'

ICONS = {
 # ---------------- medicine ----------------
 "medicine/medicine": f'<rect x="20" y="10" width="24" height="11" rx="3" {f(M)}/><rect x="16" y="21" width="32" height="35" rx="7" {f(L)}/><path d="M32 30v14M25 37h14" stroke-width="4"/>',
 "medicine/tablet": f'<circle cx="32" cy="32" r="19" {f(L)}/><path d="M19 32h26"/><path d="M24 21a13 13 0 0 1 8-3" stroke="{M}" stroke-width="3"/>',
 "medicine/capsule": f'<g transform="rotate(-40 32 32)"><path d="M32 21h12a11 11 0 0 1 0 22H32z" {f(M)}/><path d="M32 21H20a11 11 0 0 0 0 22h12z" {f(L)}/><path d="M32 21v22"/></g>',
 "medicine/vitamin": f'<rect x="22" y="9" width="20" height="10" rx="3" {f(M)}/><rect x="16" y="19" width="32" height="38" rx="7" {f(L)}/><circle cx="32" cy="38" r="9" {f(W)}/><path d="M32 33v10M27 38h10"/>',
 "medicine/syrup": f'<rect x="26" y="8" width="12" height="9" rx="2" {f(M)}/><path d="M27 17v5l-7 6v22a6 6 0 0 0 6 6h12a6 6 0 0 0 6-6V28l-7-6v-5" {f(L)}/><path d="M20 38h24v12a6 6 0 0 1-6 6H26a6 6 0 0 1-6-6z" {f(M)}/><path d="M26 31h12"/>',
 "medicine/ointment": f'<g transform="rotate(-35 32 32)"><rect x="8" y="24" width="38" height="16" rx="3" {f(L)}/><rect x="46" y="27" width="9" height="10" rx="2" {f(M)}/><path d="M12 24v16M16 24v16"/></g>',
 "medicine/ampul": f'<path d="M27 8h10v10c0 4 7 6 7 13v19a7 7 0 0 1-7 7H27a7 7 0 0 1-7-7V31c0-7 7-9 7-13z" {f(L)}/><path d="M20 38h24v12a7 7 0 0 1-7 7H27a7 7 0 0 1-7-7z" {f(M)}/><path d="M27 18h10"/>',
 "medicine/infusion": f'<rect x="17" y="6" width="30" height="38" rx="7" {f(L)}/><path d="M17 28h30v9a7 7 0 0 1-7 7H24a7 7 0 0 1-7-7z" {f(M)}/><circle cx="32" cy="12" r="2"/><path d="M38 19h4M38 24h4"/><path d="M32 44v6"/><path d="M32 53c-3 4-3 7 0 8s3-4 0-8z" {f(M)}/>',
 "medicine/suppository": f'<g transform="rotate(-40 32 32)"><path d="M10 25h26c8 0 14 3 14 7s-6 7-14 7H10a3 3 0 0 1-3-3v-8a3 3 0 0 1 3-3z" {f(L)}/><path d="M16 29h14" stroke="{M}"/></g>',
 "medicine/pill_pack": f'<rect x="8" y="14" width="48" height="36" rx="6" {f(L)}/><circle cx="21" cy="26" r="5" {f(M)}/><circle cx="32" cy="26" r="5" {f(M)}/><circle cx="43" cy="26" r="5" {f(M)}/><circle cx="21" cy="39" r="5" {f(M)}/><circle cx="32" cy="39" r="5" {f(M)}/><circle cx="43" cy="39" r="5" {f(M)}/>',
 # ---------------- service ----------------
 "service/service": f'<rect x="9" y="9" width="46" height="46" rx="11" {f(L)}/><path d="M27 17h10v10h10v10H37v10H27V37H17V27h10z" {f(M)}/>',
 "service/consultation": f'<path d="M17 9v15a11 11 0 0 0 22 0V9"/><circle cx="17" cy="8" r="2" {f(N)}/><circle cx="39" cy="8" r="2" {f(N)}/><path d="M28 35v7a11 11 0 0 0 22 0v-7"/><circle cx="50" cy="31" r="6" {f(M)}/>',
 "service/ultrasound": f'<rect x="23" y="6" width="18" height="28" rx="7" {f(L)}/><path d="M21 34h22l-4 10H25z" {f(M)}/><path d="M15 49c11 8 23 8 34 0"/><path d="M22 56c7 4 13 4 20 0"/>',
 "service/doctor": f'<circle cx="32" cy="19" r="10" {f(L)}/><path d="M11 57c0-13 9-21 21-21s21 8 21 21z" {f(L)}/><path d="M25 37l7 11 7-11"/><path d="M41 47v7M37.500 50.500h7" stroke-width="2.500"/>',
 "service/lab": f'<path d="M26 8h12M28 8v17L14 50a5 5 0 0 0 4 8h28a5 5 0 0 0 4-8L36 25V8" {f(L)}/><path d="M20 43h24l5 9a3 3 0 0 1-3 5H18a3 3 0 0 1-3-5z" {f(M)}/>',
 "service/room": f'<path d="M9 16v36"/><path d="M9 46h46v6"/><rect x="9" y="35" width="46" height="11" rx="3" {f(L)}/><rect x="13" y="28" width="15" height="7" rx="3.500" {f(M)}/><path d="M55 35v-4a4 4 0 0 0-4-4H34v8"/>',
 "service/admin": f'<rect x="13" y="11" width="38" height="46" rx="6" {f(L)}/><rect x="23" y="6" width="18" height="10" rx="3" {f(M)}/><path d="M21 28h22M21 36h22M21 44h13"/>',
 "service/nursing": f'<path d="M32 54S10 41 10 26a11 11 0 0 1 22-3 11 11 0 0 1 22 3c0 15-22 28-22 28z" {f(M)}/><path d="M32 25v12M26 31h12" stroke="{W}" stroke-width="4"/>',
 # ---------------- treatment ----------------
 "treatment/procedure": f'<rect x="9" y="22" width="46" height="34" rx="7" {f(L)}/><path d="M23 22v-5a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4v5"/><path d="M32 31v16M24 39h16" stroke-width="4"/>',
 "treatment/syringe": f'<g transform="rotate(40 32 32)"><path d="M22 6h20M32 6v10M21 16h22"/><rect x="24" y="16" width="16" height="28" rx="2" {f(L)}/><rect x="24" y="30" width="16" height="14" {f(M)}/><path d="M24 23h5M24 29h5M24 35h5"/><path d="M29 44h6v5h-6z" {f(M)}/><path d="M32 49v11"/></g>',
 "treatment/papsmear": f'<path d="M12 52L42 22" stroke-width="3.500"/><ellipse cx="46" cy="18" rx="8" ry="5.500" transform="rotate(-45 46 18)" {f(W)}/><rect x="30" y="38" width="26" height="16" rx="3" {f(L)}/><circle cx="38" cy="46" r="1.500" {f(N)}/><circle cx="46" cy="44" r="1.500" {f(N)}/><circle cx="48" cy="49" r="1.500" {f(N)}/>',
 "treatment/iud": f'<path d="M10 17c0 7 6 10 22 10s22-3 22-10" stroke-width="3"/><rect x="28.500" y="16" width="7" height="36" rx="3.500" {f(M)}/><path d="M32 52v8" stroke-dasharray="1 4"/>',
 "treatment/bandage": f'<g transform="rotate(-45 32 32)"><rect x="5" y="21" width="54" height="22" rx="9" {f(L)}/><rect x="22" y="21" width="20" height="22" {f(M)}/><circle cx="29" cy="28" r="1.500" {f(N)}/><circle cx="35" cy="28" r="1.500" {f(N)}/><circle cx="29" cy="36" r="1.500" {f(N)}/><circle cx="35" cy="36" r="1.500" {f(N)}/></g>',
 "treatment/irrigation": f'<path d="M24 6h16v9l5 7v15a5 5 0 0 1-5 5H24a5 5 0 0 1-5-5V22l5-7z" {f(L)}/><path d="M19 30h26v7a5 5 0 0 1-5 5H24a5 5 0 0 1-5-5z" {f(M)}/><path d="M32 47c-4 5-4 9 0 10s4-5 0-10z" {f(M)}/><path d="M43 50c-2 3-2 5 0 6s2-3 0-6z" {f(M)}/>',
 "treatment/pelvic": f'<circle cx="32" cy="24" r="13" {f(L)}/><path d="M32 37v20M23 47h18"/>',
 "treatment/curettage": f'<path d="M10 54L38 26" stroke-width="4"/><path d="M8 56l8-8" stroke-width="6" stroke="{M}"/><ellipse cx="45" cy="19" rx="9" ry="5.500" transform="rotate(-45 45 19)" {f(M)}/>',
 # ---------------- equipment ----------------
 "equipment/equipment": f'<rect x="9" y="22" width="46" height="34" rx="7" {f(M)}/><path d="M23 22v-5a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4v5"/><path d="M32 31v16M24 39h16" stroke="{W}" stroke-width="5"/>',
 "equipment/mask": f'<path d="M11 22c10-6 32-6 42 0v14c0 10-9 18-21 18S11 46 11 36z" {f(L)}/><path d="M18 28h28M18 34h28M20 40h24"/><path d="M11 26c-6 1-6 11 0 12M53 26c6 1 6 11 0 12"/>',
 "equipment/gloves": f'<rect x="16" y="28" width="32" height="22" rx="9" {f(L)}/><rect x="16" y="10" width="7" height="26" rx="3.500" {f(L)}/><rect x="24.500" y="6" width="7" height="30" rx="3.500" {f(L)}/><rect x="33" y="8" width="7" height="28" rx="3.500" {f(L)}/><rect x="41.500" y="13" width="7" height="23" rx="3.500" {f(L)}/><rect x="18" y="50" width="28" height="8" rx="2" {f(M)}/>',
 "equipment/tape": f'<circle cx="29" cy="32" r="21" {f(L)}/><circle cx="29" cy="32" r="8" {f(W)}/><path d="M34 53h22v-9H45" {f(M)}/>',
 "equipment/gauze": f'<rect x="10" y="14" width="44" height="36" rx="5" {f(L)}/><path d="M10 26h44M10 38h44M24 14v36M40 14v36" stroke-width="2"/><rect x="10" y="14" width="44" height="36" rx="5"/>',
 "equipment/catheter": f'<path d="M10 54L38 26" stroke-width="4"/><ellipse cx="45" cy="19" rx="10" ry="6.500" transform="rotate(-45 45 19)" {f(M)}/><path d="M10 54l-5 3M10 54l3 5"/>',
 "equipment/urine_bag": f'<path d="M32 6v8"/><path d="M19 14h26v32a9 9 0 0 1-9 9H28a9 9 0 0 1-9-9z" {f(L)}/><path d="M19 34h26v12a9 9 0 0 1-9 9H28a9 9 0 0 1-9-9z" {f(M)}/><path d="M37 21h5M37 27h5"/>',
 "equipment/scissors": f'<path d="M22 8l22 32M42 8L20 40"/><circle cx="17" cy="49" r="7" {f(M)}/><circle cx="47" cy="49" r="7" {f(M)}/>',
 "equipment/forceps": f'<path d="M30 7c0 15-9 28-11 40M34 7c0 15 9 28 11 40"/><path d="M30 7h4"/><circle cx="18" cy="53" r="6" {f(M)}/><circle cx="46" cy="53" r="6" {f(M)}/>',
 "equipment/oximeter": f'<rect x="8" y="20" width="48" height="26" rx="9" {f(L)}/><rect x="17" y="27" width="20" height="12" rx="3" {f(W)}/><path d="M20 33h3l2-4 3 8 2-4h3" stroke-width="2"/><circle cx="46" cy="33" r="3.500" {f(M)}/>',
 "equipment/testpack": f'<rect x="21" y="6" width="22" height="52" rx="7" {f(L)}/><rect x="26" y="14" width="12" height="11" rx="2" {f(W)}/><path d="M29 19.500h6"/><rect x="21" y="38" width="22" height="20" rx="6" {f(M)}/>',
 "equipment/condom": f'<rect x="9" y="14" width="46" height="36" rx="7" {f(L)}/><circle cx="32" cy="32" r="11" {f(M)}/><circle cx="32" cy="32" r="5" {f(L)}/>',
 "equipment/underpad": f'<path d="M15 18h38l7 30H8z" {f(L)}/><path d="M13 27h36M11 36h40" stroke-dasharray="3 4"/><path d="M33 40c-3 4-3 6 0 7s3-3 0-7z" {f(M)}/>',
 "equipment/jelly": f'<rect x="24" y="6" width="16" height="12" rx="3" {f(M)}/><path d="M20 18h24l3 32H17z" {f(L)}/><path d="M25 30h14M25 37h14"/><rect x="17" y="50" width="30" height="6" rx="2" {f(M)}/>',
 "equipment/cannula": f'<path d="M8 56L33 31" stroke-width="3"/><rect x="31" y="14" width="14" height="22" rx="3" transform="rotate(45 38 25)" {f(M)}/><path d="M45 12l8-4M50 18l5-1" />',
 "equipment/pot": f'<rect x="15" y="8" width="34" height="12" rx="3" {f(M)}/><path d="M18 20h28v30a7 7 0 0 1-7 7H25a7 7 0 0 1-7-7z" {f(L)}/><path d="M18 38h28v12a7 7 0 0 1-7 7H25a7 7 0 0 1-7-7z" {f(M)}/><path d="M25 29h14"/>',
 "equipment/spray": f'<rect x="14" y="26" width="28" height="31" rx="7" {f(L)}/><rect x="21" y="16" width="14" height="10" rx="2" {f(M)}/><path d="M21 16h15l9 5v6H35"/><circle cx="51" cy="14" r="1.500" {f(N)}/><circle cx="55" cy="21" r="1.500" {f(N)}/><circle cx="50" cy="26" r="1.500" {f(N)}/>',
}

root = Path(__file__).resolve().parent.parent
for name, body in ICONS.items():
    p = root / "assets" / "icons" / f"{name}.svg"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(HEAD + body + "</svg>\n", encoding="utf-8")
names = sorted(ICONS)
lines = ["// GENERATED by tool/gen_icons.py - jangan edit manual.", "",
         "/// Nama icon lokal yang tersedia di assets/icons/<nama>.svg", "const Set<String> kIconNames = {"]
lines += [f"  '{n}'," for n in names] + ["};", ""]
(root / "lib" / "core").mkdir(parents=True, exist_ok=True)
(root / "lib" / "core" / "icon_registry.dart").write_text("\n".join(lines), encoding="utf-8")
print(len(ICONS), "ikon dibuat")
