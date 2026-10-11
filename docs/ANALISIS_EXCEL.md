# Analisis `data-Alqoyyum-royal-clinic.xlsx`

Dibaca dengan openpyxl (rumus **dan** nilai cache) + dirender dengan LibreOffice untuk melihat tampilan kwitansi sebenarnya.

## 1. Isi file (13 sheet)

| Sheet | Fungsi |
|---|---|
| `HARGA` | Daftar harga. Kolom B = nama, **C = harga modal** (VLOOKUP ke workbook eksternal; berisi `#N/A`, `0`, desimal), **D = harga jual**. Baris 3–119 daftar obat, 120–140 jasa/tindakan/perlengkapan, 141–181 barang non-obat. |
| `KWITANSI FULL `, `KWITANSI jasa`, `KWITANSI obat`, `KWITANSI obat (2)`, `KWITANSI FULL  (2)`, `KWITANSI FULL  (3)` | Kwitansi standar. Harga item diambil dengan `VLOOKUP(nama, HARGA!B:D, 3)`; jumlah dikali quantity. `obat (2)` sengaja berisi `#N/A` / `#NAME?` (contoh data rusak). |
| `Kuretase`, `Kuretasi (2)`, `Kuretasi (3)`, `mabok.ngidam`, `lahiran`, `Pasang UID` | Kwitansi paket tindakan. Memuat item **di luar HARGA** (Dokter Kandungan, Tindakan Kuretasi, Lab, BHP, Ruangan, dst.) dengan nominal manual yang berbeda tiap kasus. |

Ada 3 *external link* (harga modal dan fungsi `terbilang` berasal dari add-in/workbook lain). Aplikasi tidak bergantung padanya.

## 2. Format kwitansi (sumber desain struk)

Urutan, dari atas ke bawah (semua sheet kwitansi konsisten):

1. Header tengah: **AL-QOYYUM ROYAL CLINIC** (tebal 14) · alamat · `No. SIPD : 446/SIPD-1785/DPMPTSP/2022` (hanya di sebagian sheet) · `Telp : (0264)8464554 / 0813.1314.8633 (WA)`; logo di kiri.
2. Garis ganda → judul **BUKTI PEMBAYARAN** (tebal 14) → `NO : 367/1026`.
3. `Diterima dari : Ny. <nama>` + tanggal rata kanan **`09 Oktober 2026`** (format `dd mmmm yyyy`, nama bulan Indonesia).
4. `Nama Pasien : Ny. <nama>` · `Nama Dokter : dr. Maulia Mardini, SpOG, MARS` · `Untuk Pembayaran`.
5. Baris item dikelompokkan per **label kategori** (`Jasa`, `Lab`, `Alat`, `Obat`, `BHP`) – label + titik dua hanya di baris pertama grup. Barang: `<qty> <satuan>` (`10 pcs`, `1 ampul`); jasa: tanpa qty. Kolom kanan memakai **format akuntansi**: `Rp` rata kiri, nominal rata kanan `120.000,00` (jumlah per baris = harga × qty). Garis bawah pada nominal item terakhir di kwitansi besar.
6. `Total Pembayaran` (tebal) → `Cara Pembayaran :` (kosong atau `Cash`) → `Terbilang :` (tebal, mis. *Tujuhratus Tigapuluh Sembilan Ribu Rupiah*).
7. `Diterima oleh:` (kanan) – ruang tanda tangan – nama penerima (*Nunung Nurjanah*).

**Format nomor**: `NO : {urut}/{BBTT}` (contoh `367/1026`, `339/0825`). **Terbilang**: add-in "Kombinasi Terbilang" + `PROPER()`; ratus/puluh digabung (`Tigaratus`, `Limapuluh`). Pengujian: ke-7 contoh terbilang di Excel direproduksi persis oleh `backend/app/terbilang.py`.

Page setup Excel: kertas **A4**, margin 6 mm, area cetak `A1:G25..50`. Aplikasi memakai **B5 176 × 250 mm** sesuai instruksi (konten diskalakan; lebar kolom A–G dipertahankan proporsinya).

## 3. Hasil impor produk (`backend/tools/extract_excel.py`)

* **198 produk**: 176 dari `HARGA` + 22 item tambahan dari sheet kwitansi. Per kategori: Obat 111 · BHP 48 · Tindakan 14 · Jasa 12 · Alat 10 · Lab 3.
* Kategori **tidak ada kolom di `HARGA`**; dipetakan dari blok baris + label pada sheet kwitansi (`Jasa`, `Lab`, `Obat`, `BHP`, `Alat`). Tindakan dicetak di bawah label **Jasa** pada struk (seperti Excel). Owner dapat mengubah kategori tiap produk.
* Nilai tidak valid **tidak membuat crash**: harga modal `#N/A` / `0` / kosong → `null` (14 item); baris tanpa harga jual valid dilewati dan dicatat di `seed/import_report.json`.
* **Duplikat nama**: `Prove D3-5000` (7.500 vs 7.000) dan `Urotractin` (5.500 vs 8.000) → dipakai baris pertama (perilaku VLOOKUP Excel); `Ranitidine` (harga sama) dilewati. **Mohon dicek Owner.**
* 11 item **"harga bebas"** (nominal berbeda tiap pasien: Tindakan Kuretasi, Dokter Kandungan, paket persalinan, Ruangan, dst.): kasir mengisi harga saat transaksi; server hanya menerima harga kustom untuk item bertanda ini.
* Satuan: `pcs` (default), `ampul` untuk 3 injeksi; jasa tanpa satuan.

## 4. Keputusan & asumsi (silakan koreksi bila keliru)

| # | Hal | Keputusan |
|---|---|---|
| 1 | Nomor kwitansi | Urut berlanjut mulai **368** (Excel memakai 367), format `{urut}/{BBTT}`. Server membuatnya atomik (tak bentrok multi-device). Owner bisa mengubah nomor berikutnya di Pengaturan. Pada nama file PNG `/` diganti `-` (`Struk_368-1026.png`). |
| 2 | Gaya terbilang | Mengikuti Excel (`Tigaratus`, bukan `Tiga Ratus`). Mudah diganti ke ejaan baku: `joined_terbilang=False` di `receipt.py`. |
| 3 | Gelar pasien | Excel menulis `: Ny.` tetap. Kasir cukup mengetik nama → struk menambah **Ny.**; bila kasir mengetik gelar (`Tn.`, `An.`, `Nn.`, `Drg.` …) gelar itu dipakai. |
| 4 | "Diterima dari" | Sama dengan nama pasien (di Excel pun otomatis disalin). |
| 5 | Nama dokter | `dr. Maulia Mardini, SpOG, MARS` (tanpa koma di akhir; di Excel ada koma sisa ketikan). |
| 6 | Cara Pembayaran | Excel mengisi manual (`Cash`). Aplikasi: Cash / Transfer / QRIS / Debit. |
| 7 | Diskon, bayar & kembali di struk | Excel **tidak** memilikinya → tidak dicetak (bayar & kembalian tetap tampil di layar kasir dan tersimpan). |
| 8 | Logo | Excel memakai logo lain (lengkung biru-hijau, 80×59 px, tersimpan di `assets/images/logo_excel_original.png`). Sesuai instruksi, struk memakai **logo yang Anda kirim**. |
| 9 | Judul & SIPD | `BUKTI PEMBAYARAN` dan baris SIPD dicetak (ada di sebagian sheet Excel + disebut di instruksi). |
| 10 | Struk panjang | Maks. 40 item/struk; isi yang melebihi halaman otomatis diperkecil agar tetap 1 halaman B5. |
| 11 | Owner membuat transaksi | Diizinkan ("akses penuh"); kasir hanya melihat riwayat miliknya yang aktif. |
