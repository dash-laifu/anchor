# Run app in debug mode with debug features enabled
Write-Host "Running app in debug mode with debug features..." -ForegroundColor Green
Write-Host "Debug features enabled: Debug reminders, notification tests, debug logging" -ForegroundColor Cyan
flutter run --dart-define=DEBUG_MODE=true --dart-define=DEBUG_BUILD=true
