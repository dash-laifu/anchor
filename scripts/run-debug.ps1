# Run app in debug mode with debug features enabled
Write-Host "Running app in debug mode with debug features..." -ForegroundColor Green
Write-Host "Debug features enabled: Debug reminders, notification tests, debug logging" -ForegroundColor Cyan

# Check for Android device and auto-select it
$devices = flutter devices --machine | ConvertFrom-Json
$androidDevice = $devices | Where-Object { $_.platformType -eq "android" } | Select-Object -First 1

if ($androidDevice) {
    Write-Host "Found Android device: $($androidDevice.name) ($($androidDevice.id))" -ForegroundColor Yellow
    flutter run --dart-define=DEBUG_MODE=true --dart-define=DEBUG_BUILD=true -d $androidDevice.id
} else {
    Write-Host "No Android device found. Running on any available device..." -ForegroundColor Yellow
    flutter run --dart-define=DEBUG_MODE=true --dart-define=DEBUG_BUILD=true
}
