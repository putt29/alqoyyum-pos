"""Pemetaan nama item/kategori -> icon lokal (assets/icons/<folder>/<nama>.svg)."""
import re
from typing import Optional

# Daftar ini HARUS sama dengan SVG yang dibuat oleh tools/gen_icons.py
ICON_NAMES = [
    "medicine/medicine", "medicine/tablet", "medicine/capsule", "medicine/vitamin",
    "medicine/syrup", "medicine/ointment", "medicine/ampul", "medicine/infusion",
    "medicine/suppository", "medicine/pill_pack",
    "service/service", "service/consultation", "service/ultrasound", "service/doctor",
    "service/lab", "service/room", "service/admin", "service/nursing",
    "treatment/procedure", "treatment/syringe", "treatment/papsmear", "treatment/iud",
    "treatment/bandage", "treatment/irrigation", "treatment/pelvic", "treatment/curettage",
    "equipment/equipment", "equipment/mask", "equipment/gloves", "equipment/tape",
    "equipment/gauze", "equipment/catheter", "equipment/urine_bag", "equipment/scissors",
    "equipment/forceps", "equipment/oximeter", "equipment/testpack", "equipment/condom",
    "equipment/underpad", "equipment/jelly", "equipment/cannula", "equipment/pot",
    "equipment/spray",
]

CATEGORY_ICON = {
    "Obat": "medicine/medicine",
    "Jasa": "service/service",
    "Tindakan": "treatment/procedure",
    "Lab": "service/lab",
    "BHP": "equipment/equipment",
    "Alat": "equipment/equipment",
}

# (regex, icon) - urutan penting: aturan pertama yang cocok dipakai.
_RULES = [
    (r"^injeksi$|suntik", "treatment/syringe"),
    (r"\bspu?l?uit\b|spuit|spluit", "treatment/syringe"),
    (r"konsultasi", "service/consultation"),
    (r"\busg\b(?!.*(gel|jelly))|transvaginal", "service/ultrasound"),
    (r"jelly|ultra sonic gel", "equipment/jelly"),
    (r"keperawatan", "service/nursing"),
    (r"^dokter|anestesi", "service/doctor"),
    (r"ruang|one day care", "service/room"),
    (r"administrasi|buku kia", "service/admin"),
    (r"kuret", "treatment/curettage"),
    (r"tindakan infus|infus|infusan", "medicine/infusion"),
    (r"pap\s*smear|papsmear", "treatment/papsmear"),
    (r"\biud\b|nova t", "treatment/iud"),
    (r"^gv\b", "treatment/bandage"),
    (r"irigasi", "treatment/irrigation"),
    (r"inspekulo|periksa dalam", "treatment/pelvic"),
    (r"masker|nebu|nasal 02|n95|kf94", "equipment/mask"),
    (r"handscoon|hanscoon|sarung tangan", "equipment/gloves"),
    (r"micropore|mikropore|plester|okeplast|dermafix|ultrafix", "equipment/tape"),
    (r"\bkasa\b|pembalut", "equipment/gauze"),
    (r"kateter|cath|foley", "equipment/catheter"),
    (r"urine bag", "equipment/urine_bag"),
    (r"gunting", "equipment/scissors"),
    (r"korentang", "equipment/forceps"),
    (r"oximeter", "equipment/oximeter"),
    (r"testpack", "equipment/testpack"),
    (r"kondom", "equipment/condom"),
    (r"underpad", "equipment/underpad"),
    (r"inflo|abbocath|stop cock|blood set", "equipment/cannula"),
    (r"^pot\b|pot urine|pot 50", "equipment/pot"),
    (r"desinfektan|alkohol|betadine", "equipment/spray"),
    (r"syr[uo]p|syruf|sirup", "medicine/syrup"),
    (r"supp|ovula|vagistin|trichodazol|microlax|fetik", "medicine/suppository"),
    (r"\binj\b|ampul|aqua pro|oxytocin|ceftriaxone|pumpisel", "medicine/ampul"),
    (r"cream|oint\b|salep|bioplacenton|apolar|salgen|thecorrt|stretchwell|kalgestin",
     "medicine/ointment"),
    (r"yasmin|primolut|visanne|cyclo|microgest|dismeno|regumen|noprostol|progyn|floragyn",
     "medicine/pill_pack"),
    (r"vit|folat|folamil|cal\b|caldece|day-cal|eazycal|d3|forti d|sanvita|isoflavit|mozuku|"
     r"prolacta|maltofer|feroplus|neurosanbe|curcuma|nutriflam|promavit|profertil",
     "medicine/vitamin"),
    (r"cefixime|cefadroxil|clindamycin|zibramax|sporetik|lactamam|govazol",
     "medicine/capsule"),
    (r"paracetamol|sanmol|ranitidine|loratadine|cortidex|ondansetron|tablet",
     "medicine/tablet"),
]


def pick_icon(name: str, category_name: str) -> str:
    n = (name or "").lower().strip()
    for pattern, icon in _RULES:
        if re.search(pattern, n):
            return icon
    return CATEGORY_ICON.get(category_name, "medicine/medicine")


def normalize_icon(icon_name: Optional[str], name: str, category_name: str) -> str:
    if icon_name and icon_name in ICON_NAMES:
        return icon_name
    return pick_icon(name, category_name)
