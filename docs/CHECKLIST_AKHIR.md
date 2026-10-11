# Checklist akhir — status jujur

Legenda: ✅ diuji/diverifikasi di sandbox · 🟡 sudah diimplementasikan, **belum dijalankan** (butuh Flutter/perangkat) · ⛔ tidak bisa dilakukan di sandbox

> Sandbox tidak punya akses ke `storage.googleapis.com`, `pub.dev`, `dl.google.com`, Gradle/Maven, sehingga `flutter pub get / analyze / run / build apk` **tidak dapat dijalankan** di sini. Backend (Python) dan aset diuji penuh.

| Item | Status | Catatan |
|---|---|---|
| Android app berjalan | ⛔ | Kode lengkap; belum dijalankan |
| Flutter project rapi | ✅ | `lib/{core,models,services,repositories,state,receipt,widgets,presentation}` |
| Login bekerja | ✅ API · 🟡 UI | bcrypt + JWT, tes 19 skenario API |
| Owner / Kasir bekerja | ✅ API · 🟡 UI | |
| Role restriction bekerja | ✅ | 14 endpoint Owner-only → 403 untuk kasir (di server) |
| Data Excel berhasil di-import | ✅ | 198 produk; data rusak aman (tes importer) |
| Produk, kategori, search | ✅ API · 🟡 UI | |
| Icon produk tampil | ✅ aset · 🟡 render | 43 SVG lokal, semua produk terpetakan |
| Kasir mengetik nama pasien sendiri; tanpa master pasien/HP/alamat/NIK | ✅ | hanya `transactions.patient_name` |
| Dokter tetap | ✅ | server menetapkan; input klien diabaikan |
| Cart, quantity, total | ✅ server · 🟡 UI | tes unit Dart ditulis (`test/widget_test.dart`) |
| Payment, kembalian, pesan "Nominal pembayaran belum mencukupi." | ✅ server · 🟡 UI | |
| Nomor transaksi unik | ✅ | 16 transaksi paralel → 16 nomor berbeda |
| Transaksi tersimpan; Owner melihat | ✅ | |
| Soft delete, audit log, "DIHAPUS OLEH OWNER", tidak masuk laporan | ✅ API · 🟡 UI | |
| Dashboard Owner/Kasir, laporan, ekspor PDF/Excel | ✅ API/ekspor · 🟡 UI | |
| Logo, launcher icon | ✅ aset dibuat & dipratinjau · 🟡 terpasang di APK | adaptive icon + legacy + splash native |
| Warna sesuai palet | ✅ kode | tanpa hijau pada UI (logo Anda memang hijau) |
| UI responsive / tanpa overflow | 🟡 | tablet 2 kolom, HP bottom sheet, font diklem 0.9–1.15× |
| Receipt B5 · mengikuti Excel (teks, urutan, format) | ✅ teks · 🟡 layout | isi struk dibandingkan dengan 5 kwitansi Excel (baris, total, terbilang); layout disimulasikan di `docs/perbandingan-struk-excel-vs-app.png` |
| Preview/print/PNG satu template | ✅ desain · 🟡 runtime | satu widget `ReceiptView`; PNG 2079×2953 px (300 DPI) dari widget yang sama; PDF cetak 176×250 mm |
| `flutter analyze` bersih | ⛔ | pengganti: parser Dart (54 file, 0 error sintaks) + pemeriksa silang import/nama/`Icons.*`/parameter konstruktor terhadap sumber Flutter |
| Release APK | ⛔ | siap: `mobile/build_apk.sh|ps1` atau GitHub Actions |
