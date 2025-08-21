# Google Play Store Release Scripts

param(
    [string]$Version = "",
    [switch]$Bundle = $false,
    [switch]$Apk = $false,
    [switch]$Help = $false
)

function Show-Help {
    Write-Host "🚀 Anchor Release Builder" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\scripts\release.ps1 -Version 1.0.0 -Bundle    # Build App Bundle (recommended)"
    Write-Host "  .\scripts\release.ps1 -Version 1.0.0 -Apk       # Build APK"
    Write-Host "  .\scripts\release.ps1 -Help                     # Show this help"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Version    Version number (e.g., 1.0.0)"
    Write-Host "  -Bundle     Build App Bundle (.aab)"
    Write-Host "  -Apk        Build APK (.apk)"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\scripts\release.ps1 -Version 1.0.0 -Bundle"
    Write-Host "  .\scripts\release.ps1 -Version 1.0.1 -Apk"
    Write-Host ""
}

function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    # Check Flutter
    try {
        $flutterVersion = flutter --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Flutter is installed" -ForegroundColor Green
        } else {
            throw "Flutter not found"
        }
    } catch {
        Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
    
    # Check keystore configuration
    if (!(Test-Path "android\key.properties")) {
        Write-Host "❌ android\key.properties not found" -ForegroundColor Red
        Write-Host "   Create keystore first: keytool -genkey -v -keystore anchor-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias anchor-key" -ForegroundColor Yellow
        return $false
    } else {
        Write-Host "✅ keystore configuration found" -ForegroundColor Green
    }
    
    # Check keystore file exists
    $keyProps = Get-Content "android\key.properties"
    $storeFile = ($keyProps | Where-Object { $_ -match "storeFile=" }).Split("=")[1]
    if (!(Test-Path "android\$storeFile")) {
        Write-Host "❌ Keystore file not found: android\$storeFile" -ForegroundColor Red
        return $false
    } else {
        Write-Host "✅ Keystore file found" -ForegroundColor Green
    }
    
    return $true
}

function Update-Version {
    param([string]$NewVersion)
    
    Write-Host "📝 Updating version to $NewVersion..." -ForegroundColor Yellow
    
    # Read current pubspec.yaml
    $pubspecPath = "pubspec.yaml"
    $content = Get-Content $pubspecPath
    
    # Find version line and extract build number
    $versionLine = $content | Where-Object { $_ -match "^version:" }
    if ($versionLine -match "version:\s*(.+)\+(\d+)") {
        $currentVersion = $matches[1]
        $currentBuild = [int]$matches[2]
        $newBuild = $currentBuild + 1
        
        Write-Host "   Current: $currentVersion+$currentBuild" -ForegroundColor Gray
        Write-Host "   New: $NewVersion+$newBuild" -ForegroundColor Green
        
        # Update version line
        $newVersionLine = "version: $NewVersion+$newBuild"
        $newContent = $content -replace "^version:.*", $newVersionLine
        
        # Write back to file
        $newContent | Set-Content $pubspecPath
        
        return $newBuild
    } else {
        Write-Host "❌ Could not parse version from pubspec.yaml" -ForegroundColor Red
        return $null
    }
}

function Build-Release {
    param(
        [string]$Type,
        [string]$Version,
        [int]$BuildNumber
    )
    
    Write-Host "🔨 Building $Type release..." -ForegroundColor Yellow
    
    # Clean project
    Write-Host "   Cleaning project..." -ForegroundColor Gray
    flutter clean | Out-Null
    
    # Get dependencies
    Write-Host "   Getting dependencies..." -ForegroundColor Gray
    flutter pub get | Out-Null
    
    # Build release
    $buildStart = Get-Date
    if ($Type -eq "Bundle") {
        Write-Host "   Building App Bundle..." -ForegroundColor Gray
        flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
        $outputPath = "build\app\outputs\bundle\release\app-release.aab"
    } else {
        Write-Host "   Building APK..." -ForegroundColor Gray
        flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
        $outputPath = "build\app\outputs\flutter-apk\"
    }
    
    $buildEnd = Get-Date
    $buildTime = $buildEnd - $buildStart
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build completed successfully in $($buildTime.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green
        Write-Host "📦 Output: $outputPath" -ForegroundColor Cyan
        
        # Show file size
        if ($Type -eq "Bundle") {
            $fileSize = (Get-Item $outputPath).Length / 1MB
            Write-Host "📊 File size: $($fileSize.ToString('F1')) MB" -ForegroundColor Cyan
        } else {
            $apkFiles = Get-ChildItem "$outputPath*.apk" | Where-Object { $_.Name -match "app-.*-release\.apk" }
            foreach ($apk in $apkFiles) {
                $fileSize = $apk.Length / 1MB
                Write-Host "📊 $($apk.Name): $($fileSize.ToString('F1')) MB" -ForegroundColor Cyan
            }
        }
        
        return $true
    } else {
        Write-Host "❌ Build failed" -ForegroundColor Red
        return $false
    }
}

function Show-ReleaseInfo {
    param(
        [string]$Type,
        [string]$Version,
        [int]$BuildNumber
    )
    
    Write-Host ""
    Write-Host "🎉 Release build completed!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "📱 App: Anchor - Parking Saver" -ForegroundColor White
    Write-Host "🏷️  Version: $Version+$BuildNumber" -ForegroundColor White
    Write-Host "📦 Type: $Type" -ForegroundColor White
    Write-Host "📅 Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host ""
    
    if ($Type -eq "Bundle") {
        $outputPath = "build\app\outputs\bundle\release\app-release.aab"
        Write-Host "📁 File: $outputPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Test the app: flutter install --release" -ForegroundColor White
        Write-Host "2. Upload to Play Console: $outputPath" -ForegroundColor White
        Write-Host "3. Create release notes for version $Version" -ForegroundColor White
        Write-Host "4. Submit for review" -ForegroundColor White
    } else {
        $outputDir = "build\app\outputs\flutter-apk\"
        Write-Host "📁 Directory: $outputDir" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "APK files:" -ForegroundColor Yellow
        Get-ChildItem "$outputDir*.apk" | Where-Object { $_.Name -match "app-.*-release\.apk" } | ForEach-Object {
            Write-Host "  • $($_.Name)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Test APKs on different devices" -ForegroundColor White
        Write-Host "2. Upload universal APK to Play Console" -ForegroundColor White
        Write-Host "3. Create release notes for version $Version" -ForegroundColor White
        Write-Host "4. Submit for review" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "📖 For detailed release instructions, see:" -ForegroundColor Yellow
    Write-Host "   docs\PLAYSTORE_RELEASE.md" -ForegroundColor Cyan
    Write-Host ""
}

# Main script execution
if ($Help) {
    Show-Help
    exit 0
}

if ($Version -eq "") {
    Write-Host "❌ Version parameter is required" -ForegroundColor Red
    Write-Host "   Use -Help for usage information" -ForegroundColor Yellow
    exit 1
}

if (!$Bundle -and !$Apk) {
    Write-Host "❌ Must specify either -Bundle or -Apk" -ForegroundColor Red
    Write-Host "   Use -Help for usage information" -ForegroundColor Yellow
    exit 1
}

if ($Bundle -and $Apk) {
    Write-Host "❌ Cannot specify both -Bundle and -Apk" -ForegroundColor Red
    Write-Host "   Use -Help for usage information" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Anchor Release Builder" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

# Check prerequisites
if (!(Test-Prerequisites)) {
    Write-Host "❌ Prerequisites not met. Please fix the issues above." -ForegroundColor Red
    exit 1
}

# Update version
$buildNumber = Update-Version -NewVersion $Version
if ($buildNumber -eq $null) {
    Write-Host "❌ Failed to update version" -ForegroundColor Red
    exit 1
}

# Determine build type
$buildType = if ($Bundle) { "Bundle" } else { "Apk" }

# Build release
$success = Build-Release -Type $buildType -Version $Version -BuildNumber $buildNumber
if (!$success) {
    Write-Host "❌ Release build failed" -ForegroundColor Red
    exit 1
}

# Show release information
Show-ReleaseInfo -Type $buildType -Version $Version -BuildNumber $buildNumber

exit 0
