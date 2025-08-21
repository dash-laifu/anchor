# Build production APK (no debug features)
Write-Host "Building production APK..." -ForegroundColor Green
flutter build apk --release
Write-Host "Production APK built successfully!" -ForegroundColor Green
Write-Host "Location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
