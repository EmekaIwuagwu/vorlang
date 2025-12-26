# Vorlang Windows Installer v0.10-super
# Date: December 27, 2025

$ErrorActionPreference = "Stop"

$VERSION = "v0.10-super"
$REPO_URL = "https://github.com/EmekaIwuagwu/vorlang"
$BASE_DIR = "C:\Vorlang"
$BIN_DIR = "$BASE_DIR\bin"
$SHARE_DIR = "$BASE_DIR\share"

Write-Host "🛡️  Installing Vorlang $VERSION..." -ForegroundColor Cyan

# 1. Admin Check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator."
    return
}

# 2. Dependency Check/Install
Write-Host "� Checking dependencies..." -ForegroundColor Gray
if (!(Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..."
    winget install --id Git.Git -e --source winget
}
if (!(Get-Command "make" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Make..."
    choco install make -y | Out-Null # Fallback to winget if choco missing?
}

# 3. Download and Build
$tempDir = New-TemporaryFile | % { $_.FullName; Remove-Item $_ }
New-Item -ItemType Directory -Path $tempDir
Set-Location $tempDir

Write-Host "📂 Downloading source..." -ForegroundColor Gray
git clone --depth 1 $REPO_URL .

Write-Host "🏗️  Building compiler..." -ForegroundColor Gray
& make

if (!(Test-Path ".\vorlangc")) {
    Write-Error "Build failed."
}

# 4. Install
Write-Host "🚚 Installing to $BASE_DIR..." -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $SHARE_DIR | Out-Null

Copy-Item ".\vorlangc" -Destination "$BIN_DIR\vorlangc.exe"
Copy-Item -Recurse ".\stdlib" -Destination "$SHARE_DIR\"
Copy-Item -Recurse ".\examples" -Destination "$SHARE_DIR\"

# 5. Path Updates
Write-Host "🔗 Configuring environment..." -ForegroundColor Gray
$OldPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($OldPath -notlike "*$BIN_DIR*") {
    [Environment]::SetEnvironmentVariable("Path", "$OldPath;$BIN_DIR", "Machine")
    Write-Host "✅ Added $BIN_DIR to PATH." -ForegroundColor Green
}
[Environment]::SetEnvironmentVariable("VORLANG_STDLIB", "$SHARE_DIR\stdlib", "Machine")

# 6. Smoke Test
Write-Host "🧪 Running smoke test..." -ForegroundColor Gray
$test = & "$BIN_DIR\vorlangc.exe" run ".\examples\test_simple.vorlang"
if ($test -like "*PASS*") {
    Write-Host "✅ Vorlang $VERSION installed and verified!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Installation finished, but smoke test failed." -ForegroundColor Yellow
}

Write-Host "`nPlease restart your terminal to use 'vorlangc'." -ForegroundColor Yellow
