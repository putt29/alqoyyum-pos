#!/usr/bin/env bash
# Build APK release AL-QOYYUM Kasir (Linux / macOS / Git Bash).
# Pakai: ./build_apk.sh http://192.168.1.10:8000
set -e
API_URL="${1:-http://192.168.1.10:8000}"
cd "$(dirname "$0")"

# 1) Buat scaffold Android (gradle, MainActivity). File proyek yang sudah ada tidak ditimpa.
flutter create --platforms=android --org id.alqoyyum --project-name alqoyyum_pos .
# 2) Dependensi
flutter pub get
# 3) Analisis & tes (catatan ditampilkan, build tetap lanjut)
flutter analyze || echo ">> flutter analyze menemukan catatan (lihat di atas)."
flutter test || echo ">> flutter test gagal (lihat di atas)."
# 4) APK release
flutter build apk --release --dart-define=API_BASE_URL="$API_URL"
echo
echo "APK: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
