# Clean build files and get dependencies
Write-Host "Cleaning Flutter project..." -ForegroundColor Green
flutter clean
Write-Host "Getting dependencies..." -ForegroundColor Green
flutter pub get
Write-Host "Project cleaned and dependencies updated!" -ForegroundColor Green
