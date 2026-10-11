# AL-QOYYUM ROYAL CLINIC — Aplikasi Kasir (Flutter Android + backend terpusat)

Aplikasi kasir klinik pribadi (dokter tetap **dr. Maulia Mardini, SpOG, MARS**): login Owner/Kasir, POS cepat, nama pasien **diketik langsung** (tanpa master pasien), struk **B5 176×250 mm** yang mengikuti kwitansi Excel, laporan, soft delete + audit log, multi-device lewat server terpusat.

```
backend/   FastAPI + SQLite (sumber kebenaran data, otorisasi di server)   ← diuji (29 tes otomatis)
mobile/    Proyek Flutter Android (lib/, aset, ikon launcher, manifest)      ← kode lengkap, BELUM dikompilasi (lihat bawah)
docs/      ANALISIS_EXCEL.md · CHECKLIST_AKHIR.md · perbandingan struk
.github/   workflow GitHub Actions untuk membangun APK tanpa memasang Flutter
```

> **Jujur soal status:** pembuatan ini dilakukan di sandbox tanpa akses ke Flutter SDK / pub.dev / Android SDK, jadi
> `flutter pub get`, `flutter analyze`, `flutter run`, dan `flutter build apk` **belum dijalankan**. Yang sudah diverifikasi:
> backend & datanya (tes), isi struk vs 5 kwitansi Excel, aset (logo, ikon launcher, 43 ikon SVG), dan kode Dart lolos parser
> (54 file, 0 error sintaks) + pemeriksaan silang import/nama/parameter terhadap sumber Flutter. Detail: `docs/CHECKLIST_AKHIR.md`.
> Jika build Anda menampilkan error, kirimkan teks errornya — kemungkinan perbaikannya kecil.

## 1. Jalankan backend

Python 3.10+.

```bash
cd backend
python -m venv .venv && source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python -m app.seed --owner-password 'PasswordKuat123'     # katalog dari Excel + akun Owner  (+ --demo-cashier untuk uji)
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Atau Docker: `cp .env.example .env` (isi `OWNER_PASSWORD`) lalu `docker compose up -d --build`.
Cek: `http://<ip-server>:8000/api/health` · dokumentasi API otomatis: `/docs`.

* Database: file SQLite (`backend/data/alqoyyum.db`, atau volume `/data` di Docker). **Cadangkan berkala.**
* Di jaringan klinik: jalankan di satu PC/mini-PC yang selalu menyala; semua HP/tablet terhubung ke IP-nya.
  Lewat internet: pasang di VPS dan beri **HTTPS** (mis. Caddy/Nginx reverse proxy). Manifest mengizinkan `http://` agar jaringan lokal bisa dipakai.
* Impor ulang dari Excel: `python tools/extract_excel.py file.xlsx` → `seed/products.json` → `python -m app.seed`.

## 2. Bangun APK

Pilih salah satu:

**A. Lokal** (Flutter stable terpasang + Android SDK):
```bash
cd mobile
./build_apk.sh http://192.168.1.10:8000        # Windows: .\build_apk.ps1 -ApiUrl http://192.168.1.10:8000
# hasil: mobile/build/app/outputs/flutter-apk/app-release.apk
```
Skrip menjalankan `flutter create --platforms=android .` (membuat file Gradle sesuai versi Flutter Anda; **tidak menimpa** manifest/ikon/tema splash yang sudah ada), `flutter pub get`, `flutter analyze`, `flutter test`, lalu `flutter build apk --release`.

**B. GitHub Actions** (tanpa memasang apa pun): unggah folder ini ke repo GitHub → **Actions → "Build APK AL-QOYYUM Kasir" → Run workflow** → isi alamat server → unduh APK dari *Artifacts*.

Alamat server juga bisa diubah di aplikasi (ikon ⚙ di halaman login / menu Pengaturan) tanpa build ulang.
APK release memakai kunci debug bawaan Flutter (cukup untuk dipasang langsung). Untuk Play Store, siapkan keystore sendiri.

## 3. Pemakaian pertama

1. Login `owner` → menu **Kasir** → tambah akun kasir (mis. *Nunung Nurjanah* — namanya tercetak di "Diterima oleh").
2. **Pengaturan → Nomor kwitansi berikutnya** (default 368, lanjutan dari 367 di Excel).
3. **Produk**: periksa harga/kategori hasil impor (lihat `docs/ANALISIS_EXCEL.md`, termasuk 2 duplikat berharga beda).
4. Kasir: **Transaksi Baru** → ketik nama pasien → ketuk item → bayar → *Bayar & Simpan* → preview struk → **Print / Download PNG / Bagikan**.

Hak akses (dicek di server, bukan sekadar menyembunyikan tombol): Kasir hanya membuat transaksi & melihat riwayat miliknya; hapus transaksi, harga/produk, laporan, audit log, akun kasir = Owner saja.

## 4. Struk B5

* Isi struk disusun server (`backend/app/receipt.py`: teks, urutan, format `120.000,00`, tanggal `09 Oktober 2026`, nomor `NO : 368/1026`, terbilang ala Excel) dan digambar **satu template** Flutter (`mobile/lib/receipt/receipt_view.dart`) yang dipakai preview, print, dan PNG.
* PNG: 2079×2953 px (≈300 DPI, metadata pHYs) — bukan screenshot layar; nama `Struk_368-1026.png` (tersimpan di galeri, album *AL-QOYYUM*).
* Print: dialog cetak Android dengan halaman PDF tepat **176×250 mm**. Pilih ukuran kertas B5 / kustom 176×250 di dialog; jangan A4.
* Font struk **Carlito** (setara Calibri di Excel; lisensi OFL di `mobile/assets/fonts`).
* Ubah tampilan: konstanta ukuran/kolom di `receipt_view.dart`; ubah teks di `receipt.py`. Pratinjau desain: `docs/perbandingan-struk-excel-vs-app.png` (simulasi Python, bukan render Flutter).

## 5. Keamanan

Password bcrypt · JWT 12 jam (dicabut saat password diganti / akun dinonaktifkan) · batas percobaan login · harga dihitung ulang di server (klien tak bisa memalsukan harga/total/dokter) · transaksi atomik, nomor unik · soft delete + audit log · token disimpan di Android Keystore (`flutter_secure_storage`).

## 6. Tes

```bash
cd backend && pip install -r requirements-dev.txt && python -m pytest tests -q     # 29 tes
cd mobile && flutter test                                                          # tes unit Dart (belum dijalankan di sandbox)
```
