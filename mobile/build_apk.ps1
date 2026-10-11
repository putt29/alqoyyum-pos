# Build APK release AL-QOYYUM Kasir (Windows PowerShell).
# Pakai: .\build_apk.ps1 -ApiUrl http://192.168.1.10:8000
param([string]$ApiUrl = "http://192.168.1.10:8000")
Set-Location $PSScriptRoot

# 1) Buat scaffold Android (gradle, MainActivity). File proyek yang sudah ada tidak ditimpa.
flutter create --platforms=android --org id.alqoyyum --project-name alqoyyum_pos .
# 2) Dependensi
flutter pub get
# 3) Analisis & tes (catatan ditampilkan, build tetap lanjut)
flutter analyze
flutter test
# 4) APK release
flutter build apk --release --dart-define=API_BASE_URL=$ApiUrl
Write-Host ""
Write-Host "APK: $PSScriptRoot\build\app\outputs\flutter-apk\app-release.apk"
