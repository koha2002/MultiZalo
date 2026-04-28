# Build ZaloMulti.ps1 to ZaloMulti.exe
# Run on Windows PowerShell.
# Output: ZaloMulti.exe

$ErrorActionPreference = "Stop"

$ScriptFile = Join-Path $PSScriptRoot "ZaloMulti.ps1"
$OutputFile = Join-Path $PSScriptRoot "ZaloMulti.exe"
$IconFile = Join-Path $PSScriptRoot "logo.ico"

if (-not (Test-Path -LiteralPath $ScriptFile)) {
    Write-Host "Missing file: $ScriptFile" -ForegroundColor Red
    exit 1
}

Write-Host "Checking ps2exe..." -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing ps2exe for current user..." -ForegroundColor Yellow
    Install-Module ps2exe -Scope CurrentUser -Force
}

Import-Module ps2exe -Force

if (Test-Path -LiteralPath $OutputFile) {
    Remove-Item -LiteralPath $OutputFile -Force
}

Write-Host "Building ZaloMulti.exe..." -ForegroundColor Cyan

$commonArgs = @{
    inputFile = $ScriptFile
    outputFile = $OutputFile
    noConsole = $true
    title = "ZaloMulti"
    description = "ZaloMulti - koha.io.vn"
    company = "Nguyễn Lê Khánh Hòa"
    product = "ZaloMulti"
    copyright = "Nguyễn Lê Khánh Hòa"
}

if (Test-Path -LiteralPath $IconFile) {
    Invoke-ps2exe @commonArgs -iconFile $IconFile
} else {
    Invoke-ps2exe @commonArgs
}

if (Test-Path -LiteralPath $OutputFile) {
    $sizeKb = [Math]::Round((Get-Item -LiteralPath $OutputFile).Length / 1KB, 0)
    Write-Host ""
    Write-Host "Done: $OutputFile ($sizeKb KB)" -ForegroundColor Green
    Write-Host "Send only ZaloMulti.exe to users." -ForegroundColor Green
} else {
    Write-Host "Build failed." -ForegroundColor Red
    exit 1
}

Read-Host "Press Enter to exit"
