# Build debug APK with debug features enabled
Write-Host "Building debug APK with debug features..." -ForegroundColor Green
flutter build apk --debug --dart-define=DEBUG_MODE=true --dart-define=DEBUG_BUILD=true
Write-Host "Debug APK built successfully!" -ForegroundColor Green
Write-Host "Location: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Yellow
Write-Host "Debug features enabled: Debug reminders, notification tests, debug logging" -ForegroundColor Cyan
