"""Konfigurasi aplikasi. Semua bisa di-override lewat environment variable."""
import os
from pathlib import Path
from zoneinfo import ZoneInfo

BASE_DIR = Path(__file__).resolve().parent.parent

DB_PATH = Path(os.environ.get("DB_PATH", str(BASE_DIR / "data" / "alqoyyum.db")))
SEED_DIR = Path(os.environ.get("SEED_DIR", str(BASE_DIR / "seed")))

# Jika kosong, secret dibuat otomatis & disimpan di tabel settings (aman untuk 1 server).
JWT_SECRET = os.environ.get("JWT_SECRET", "")
TOKEN_TTL_MINUTES = int(os.environ.get("TOKEN_TTL_MINUTES", "720"))  # 12 jam

TZ = ZoneInfo(os.environ.get("APP_TZ", "Asia/Jakarta"))

# ---- Identitas klinik (sesuai Excel & instruksi) ----
CLINIC_NAME = "AL-QOYYUM ROYAL CLINIC"
CLINIC_ADDRESS = "Jl. Buana Indah No.61 Cihideung-Sadang-Purwakarta"
CLINIC_SIPD_LINE = "No. SIPD : 446/SIPD-1785/DPMPTSP/2022"
CLINIC_PHONE_LINE = "Telp : (0264)8464554 / 0813.1314.8633 (WA)"
CLINIC_PHONE = "(0264) 8464554"
CLINIC_WHATSAPP = "0813.1314.8633"
CLINIC_SIPD = "446/SIPD-1785/DPMPTSP/2022"

# Dokter TETAP (klinik pribadi, tidak ada master dokter).
DOCTOR_TITLE = "dr."
DOCTOR_NAME = "Maulia Mardini, SpOG, MARS"
DOCTOR_FULL = f"{DOCTOR_TITLE} {DOCTOR_NAME}"

# Nomor kwitansi di Excel: "NO : 367/1026" => {urut}/{MMYY}.
# Nomor berikutnya default 368 (setelah contoh 367 di Excel); Owner bisa mengubahnya.
DEFAULT_NEXT_SEQUENCE = int(os.environ.get("DEFAULT_NEXT_SEQUENCE", "368"))

PAYMENT_METHODS = ("Cash", "Transfer", "QRIS", "Debit")
MAX_ITEMS_PER_TX = 40
MAX_PASSWORD_BYTES = 72  # batas bcrypt
MIN_PASSWORD_LEN = 6
