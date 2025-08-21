# Keystore Setup Script for Anchor Release

param(
    [switch]$Help = $false
)

function Show-Help {
    Write-Host "🔑 Anchor Keystore Setup" -ForegroundColor Green
    Write-Host ""
    Write-Host "This script helps you create a signing keystore for Google Play Store releases."
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\scripts\setup-keystore.ps1        # Interactive keystore creation"
    Write-Host "  .\scripts\setup-keystore.ps1 -Help  # Show this help"
    Write-Host ""
    Write-Host "What this script does:" -ForegroundColor Yellow
    Write-Host "  1. Generates a release keystore file"
    Write-Host "  2. Creates key.properties configuration"
    Write-Host "  3. Provides security best practices"
    Write-Host "  4. Tests the keystore configuration"
    Write-Host ""
    Write-Host "Requirements:" -ForegroundColor Yellow
    Write-Host "  • Java Development Kit (JDK) installed"
    Write-Host "  • keytool command available in PATH"
    Write-Host ""
}

function Test-JavaInstallation {
    Write-Host "🔍 Checking Java installation..." -ForegroundColor Yellow
    
    try {
        $javaVersion = java -version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Java is installed" -ForegroundColor Green
            
            # Check for keytool
            $keytoolVersion = keytool -help 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ keytool is available" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ keytool not found in PATH" -ForegroundColor Red
                Write-Host "   keytool should be available with JDK installation" -ForegroundColor Yellow
                return $false
            }
        } else {
            throw "Java not found"
        }
    } catch {
        Write-Host "❌ Java is not installed or not in PATH" -ForegroundColor Red
        Write-Host "   Please install Java Development Kit (JDK 8 or higher)" -ForegroundColor Yellow
        Write-Host "   Download from: https://adoptium.net/" -ForegroundColor Cyan
        return $false
    }
}

function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$DefaultValue = "",
        [switch]$Secure = $false
    )
    
    if ($DefaultValue -ne "") {
        $fullPrompt = "$Prompt [$DefaultValue]"
    } else {
        $fullPrompt = $Prompt
    }
    
    if ($Secure) {
        $input = Read-Host -Prompt $fullPrompt -AsSecureString
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($input))
    } else {
        $input = Read-Host -Prompt $fullPrompt
        if ($input -eq "" -and $DefaultValue -ne "") {
            return $DefaultValue
        }
        return $input
    }
}

function New-Keystore {
    Write-Host "🔑 Creating new keystore..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please provide the following information for your keystore:" -ForegroundColor Cyan
    Write-Host ""
    
    # Get keystore information
    $keystorePassword = Get-UserInput -Prompt "Keystore password (choose a strong password)" -Secure
    $keystorePasswordConfirm = Get-UserInput -Prompt "Confirm keystore password" -Secure
    
    if ($keystorePassword -ne $keystorePasswordConfirm) {
        Write-Host "❌ Passwords do not match" -ForegroundColor Red
        return $false
    }
    
    $keyPassword = Get-UserInput -Prompt "Key password (can be same as keystore password)" -Secure
    
    Write-Host ""
    Write-Host "Distinguished Name information:" -ForegroundColor Cyan
    $firstName = Get-UserInput -Prompt "First and last name" -DefaultValue "Anchor Parking App"
    $organization = Get-UserInput -Prompt "Organization" -DefaultValue "dash-laifu"
    $organizationUnit = Get-UserInput -Prompt "Organizational unit" -DefaultValue "Development"
    $city = Get-UserInput -Prompt "City or locality" -DefaultValue "Your City"
    $state = Get-UserInput -Prompt "State or province" -DefaultValue "Your State"
    $country = Get-UserInput -Prompt "Two-letter country code" -DefaultValue "US"
    
    # Create keystore
    Write-Host ""
    Write-Host "🔨 Generating keystore..." -ForegroundColor Yellow
    
    $keystorePath = "android\anchor-release-key.keystore"
    $alias = "anchor-key"
    
    # Build distinguished name
    $dn = "CN=$firstName, OU=$organizationUnit, O=$organization, L=$city, S=$state, C=$country"
    
    # Create keystore command
    $env:KEYSTORE_PASSWORD = $keystorePassword
    $env:KEY_PASSWORD = $keyPassword
    
    try {
        # Use environment variables to avoid password exposure in command line
        $process = Start-Process -FilePath "keytool" -ArgumentList @(
            "-genkey", "-v",
            "-keystore", $keystorePath,
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "10000",
            "-alias", $alias,
            "-dname", $dn,
            "-storepass", $keystorePassword,
            "-keypass", $keyPassword
        ) -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "✅ Keystore created successfully" -ForegroundColor Green
            
            # Create key.properties file
            $keyPropertiesContent = @"
storePassword=$keystorePassword
keyPassword=$keyPassword
keyAlias=$alias
storeFile=anchor-release-key.keystore
"@
            
            $keyPropertiesPath = "android\key.properties"
            $keyPropertiesContent | Set-Content -Path $keyPropertiesPath
            
            Write-Host "✅ key.properties file created" -ForegroundColor Green
            
            return $true
        } else {
            Write-Host "❌ Failed to create keystore" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error creating keystore: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        # Clear environment variables
        Remove-Item env:KEYSTORE_PASSWORD -ErrorAction SilentlyContinue
        Remove-Item env:KEY_PASSWORD -ErrorAction SilentlyContinue
    }
}

function Test-KeystoreSetup {
    Write-Host "🧪 Testing keystore setup..." -ForegroundColor Yellow
    
    # Check if files exist
    $keystorePath = "android\anchor-release-key.keystore"
    $keyPropertiesPath = "android\key.properties"
    
    if (!(Test-Path $keystorePath)) {
        Write-Host "❌ Keystore file not found: $keystorePath" -ForegroundColor Red
        return $false
    }
    
    if (!(Test-Path $keyPropertiesPath)) {
        Write-Host "❌ key.properties file not found: $keyPropertiesPath" -ForegroundColor Red
        return $false
    }
    
    # Test keystore accessibility
    try {
        $keyProps = Get-Content $keyPropertiesPath
        $storePassword = ($keyProps | Where-Object { $_ -match "storePassword=" }).Split("=")[1]
        $alias = ($keyProps | Where-Object { $_ -match "keyAlias=" }).Split("=")[1]
        
        $listOutput = keytool -list -keystore $keystorePath -alias $alias -storepass $storePassword 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Keystore is accessible and valid" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Cannot access keystore or alias" -ForegroundColor Red
            Write-Host "   $listOutput" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "❌ Error testing keystore: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-SecurityGuidance {
    Write-Host ""
    Write-Host "🛡️  IMPORTANT SECURITY NOTES" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔒 BACKUP YOUR KEYSTORE:" -ForegroundColor Yellow
    Write-Host "   • Copy anchor-release-key.keystore to a secure location"
    Write-Host "   • Store passwords in a secure password manager"
    Write-Host "   • Create multiple backups (cloud storage, external drive)"
    Write-Host "   • Test backups periodically"
    Write-Host ""
    Write-Host "⚠️  LOSING YOUR KEYSTORE MEANS:" -ForegroundColor Red
    Write-Host "   • You cannot update your published app"
    Write-Host "   • You must publish a new app with different package name"
    Write-Host "   • All existing users cannot update to new versions"
    Write-Host ""
    Write-Host "🚫 NEVER:" -ForegroundColor Red
    Write-Host "   • Commit keystore files to version control (git)"
    Write-Host "   • Share keystore files publicly"
    Write-Host "   • Use weak passwords"
    Write-Host "   • Store passwords in plain text files"
    Write-Host ""
    Write-Host "✅ RECOMMENDED:" -ForegroundColor Green
    Write-Host "   • Use Google Play App Signing (upload key protection)"
    Write-Host "   • Store keystore in encrypted cloud storage"
    Write-Host "   • Use different passwords for keystore and key"
    Write-Host "   • Document keystore location and access procedure"
    Write-Host ""
    Write-Host "📁 Files created:" -ForegroundColor Cyan
    Write-Host "   • android\anchor-release-key.keystore (SECURE THIS FILE)"
    Write-Host "   • android\key.properties (excluded from git)"
    Write-Host ""
}

function Show-NextSteps {
    Write-Host "🚀 NEXT STEPS" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "1. 🔐 Secure your keystore files immediately" -ForegroundColor Yellow
    Write-Host "2. 📦 Build release with: .\scripts\release.ps1 -Version 1.0.0 -Bundle" -ForegroundColor Yellow
    Write-Host "3. 🧪 Test the release build thoroughly" -ForegroundColor Yellow
    Write-Host "4. 📱 Upload to Google Play Console" -ForegroundColor Yellow
    Write-Host "5. 📖 Follow docs\PLAYSTORE_RELEASE.md for complete guide" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Build commands:" -ForegroundColor Cyan
    Write-Host "   App Bundle (recommended): .\scripts\release.ps1 -Version 1.0.0 -Bundle"
    Write-Host "   APK alternative:           .\scripts\release.ps1 -Version 1.0.0 -Apk"
    Write-Host ""
}

# Main script execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🔑 Anchor Keystore Setup" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

# Check if keystore already exists
if (Test-Path "android\anchor-release-key.keystore") {
    Write-Host "⚠️  Keystore already exists: android\anchor-release-key.keystore" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "❌ Aborted. Existing keystore preserved." -ForegroundColor Red
        exit 0
    }
    Write-Host ""
}

# Check Java installation
if (!(Test-JavaInstallation)) {
    Write-Host "❌ Prerequisites not met. Please install Java JDK." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "This script will create a signing keystore for releasing your app to Google Play Store." -ForegroundColor Cyan
Write-Host "You will need to provide passwords and identifying information." -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Continue with keystore creation? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "❌ Aborted by user." -ForegroundColor Red
    exit 0
}

Write-Host ""

# Create keystore
$success = New-Keystore
if (!$success) {
    Write-Host "❌ Keystore creation failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test keystore setup
$testSuccess = Test-KeystoreSetup
if (!$testSuccess) {
    Write-Host "❌ Keystore setup verification failed" -ForegroundColor Red
    exit 1
}

# Show security guidance
Show-SecurityGuidance

# Show next steps
Show-NextSteps

Write-Host "🎉 Keystore setup completed successfully!" -ForegroundColor Green
Write-Host ""

exit 0
