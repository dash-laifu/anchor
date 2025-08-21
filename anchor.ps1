# Anchor App Build & Run Scripts
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("build", "build-debug", "run", "run-debug", "clean", "install", "help")]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [string]$Mode
)

function Show-Help {
    Write-Host "Anchor App - Build & Run Scripts" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\anchor.ps1 <command> [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  build        - Build production APK (no debug features)" -ForegroundColor White
    Write-Host "  build-debug  - Build debug APK with debug features" -ForegroundColor White
    Write-Host "  run          - Run app in production mode" -ForegroundColor White
    Write-Host "  run-debug    - Run app in debug mode with debug features" -ForegroundColor White
    Write-Host "  clean        - Clean build files and get dependencies" -ForegroundColor White
    Write-Host "  install      - Install APK to device" -ForegroundColor White
    Write-Host "  help         - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Install options:" -ForegroundColor Cyan
    Write-Host "  .\anchor.ps1 install debug    - Install debug APK" -ForegroundColor White
    Write-Host "  .\anchor.ps1 install release  - Install release APK" -ForegroundColor White
    Write-Host ""
    Write-Host "Debug Features (when enabled):" -ForegroundColor Cyan
    Write-Host "  - 1-5 minute reminder options for quick testing" -ForegroundColor White
    Write-Host "  - Notification test tools in Settings" -ForegroundColor White
    Write-Host "  - Debug logging enabled" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\anchor.ps1 run-debug        # Run with debug features" -ForegroundColor White
    Write-Host "  .\anchor.ps1 build            # Build production APK" -ForegroundColor White
    Write-Host "  .\anchor.ps1 build-debug      # Build debug APK" -ForegroundColor White
    Write-Host "  .\anchor.ps1 install debug    # Install debug APK" -ForegroundColor White
}

switch ($Command) {
    "build" {
        & ".\scripts\build.ps1"
    }
    "build-debug" {
        & ".\scripts\build-debug.ps1"
    }
    "run" {
        & ".\scripts\run.ps1"
    }
    "run-debug" {
        & ".\scripts\run-debug.ps1"
    }
    "clean" {
        & ".\scripts\clean.ps1"
    }
    "install" {
        if ($Mode) {
            & ".\scripts\install.ps1" -Mode $Mode
        } else {
            & ".\scripts\install.ps1"
        }
    }
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
}
