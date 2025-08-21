# Install the APK to connected device
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("debug", "release")]
    [string]$Mode = "debug"
)

$apkPath = if ($Mode -eq "debug") {
    "build\app\outputs\flutter-apk\app-debug.apk"
} else {
    "build\app\outputs\flutter-apk\app-release.apk"
}

if (Test-Path $apkPath) {
    Write-Host "Installing $Mode APK..." -ForegroundColor Green
    flutter install --use-application-binary=$apkPath
    Write-Host "APK installed successfully!" -ForegroundColor Green
} else {
    Write-Host "APK not found: $apkPath" -ForegroundColor Red
    Write-Host "Please build the APK first using build.ps1 or build-debug.ps1" -ForegroundColor Yellow
}
