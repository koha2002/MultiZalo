# Koha Zalo Multi - Personal Launcher
# Version: 1.0.2
# Purpose: Run multiple isolated Zalo Desktop profiles without creating extra Windows users.
# This script does not patch or modify Zalo.exe. It only starts Zalo.exe with separate environment paths.

param(
    [string]$LaunchProfile = "",
    [switch]$CheckUpdateOnly
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# =============================
# CONFIG
# =============================
$Global:AppName = "Koha Zalo Multi"
$Global:Version = "1.0.2"
$Global:Owner = "koha2002"
$Global:Repo = "KohaZaloMulti"
$Global:Branch = "main"
$Global:RemoteBase = "https://raw.githubusercontent.com/$($Global:Owner)/$($Global:Repo)/$($Global:Branch)"

$Global:AppDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$Global:DataRoot = Join-Path $env:LOCALAPPDATA "KohaZaloMulti"
$Global:ProfileRoot = Join-Path $Global:DataRoot "Profiles"
$Global:ConfigFile = Join-Path $Global:DataRoot "config.json"
$Global:ScriptPath = $MyInvocation.MyCommand.Path

$Global:Window = $null
$Global:ProfileList = $null
$Global:StatusText = $null

# =============================
# BASIC HELPERS
# =============================
function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Show-Info {
    param([string]$Message, [string]$Title = $Global:AppName)
    [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
}

function Show-ErrorBox {
    param([string]$Message, [string]$Title = $Global:AppName)
    [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
}

function Set-Status {
    param([string]$Message)
    if ($null -ne $Global:StatusText) {
        $Global:StatusText.Text = $Message
    }
}

function Load-Config {
    Ensure-Directory $Global:DataRoot
    Ensure-Directory $Global:ProfileRoot

    if (Test-Path -LiteralPath $Global:ConfigFile) {
        try {
            $cfg = Get-Content -LiteralPath $Global:ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($cfg.ProfileRoot) {
                $Global:ProfileRoot = [string]$cfg.ProfileRoot
            }
        } catch {
            # Ignore broken config and continue with defaults.
        }
    }

    Ensure-Directory $Global:ProfileRoot
}

function Save-Config {
    Ensure-Directory $Global:DataRoot
    $cfg = [ordered]@{
        AppName = $Global:AppName
        Version = $Global:Version
        ProfileRoot = $Global:ProfileRoot
        UpdatedAt = (Get-Date).ToString("s")
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Global:ConfigFile, ($cfg | ConvertTo-Json -Depth 5), $utf8NoBom)
}

function Find-ZaloExe {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Zalo\Zalo.exe"),
        "C:\Program Files\Zalo\Zalo.exe",
        "C:\Program Files (x86)\Zalo\Zalo.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return ""
}

function Get-SafeName {
    param([string]$Name)
    if ($null -eq $Name) { return "" }

    $safe = $Name.Trim()
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($ch in $invalid) {
        $safe = $safe.Replace($ch, "-")
    }
    $safe = $safe -replace "\s+", " "
    return $safe.Trim()
}

function Get-Profiles {
    Ensure-Directory $Global:ProfileRoot
    return @(Get-ChildItem -LiteralPath $Global:ProfileRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
}

function Get-ProfilePath {
    param([string]$Name)
    return Join-Path $Global:ProfileRoot $Name
}

function Is-ProfileRunning {
    param([string]$Name)

    $profilePath = Get-ProfilePath $Name
    $pidFile = Join-Path $profilePath "pid.txt"
    if (-not (Test-Path -LiteralPath $pidFile)) { return $false }

    try {
        $pidValue = (Get-Content -LiteralPath $pidFile -Raw -ErrorAction Stop).Trim()
        if (-not $pidValue) { return $false }
        $proc = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
        return ($null -ne $proc)
    } catch {
        return $false
    }
}

# =============================
# PROFILE ACTIONS
# =============================
function New-ZaloProfile {
    param([string]$Name)

    $safeName = Get-SafeName $Name
    if (-not $safeName) {
        Show-ErrorBox "Profile name cannot be empty."
        return
    }

    $profilePath = Get-ProfilePath $safeName
    if (Test-Path -LiteralPath $profilePath) {
        Show-ErrorBox "Profile already exists: $safeName"
        return
    }

    Ensure-Directory $profilePath
    Ensure-Directory (Join-Path $profilePath "AppData\Roaming")
    Ensure-Directory (Join-Path $profilePath "AppData\Local")

    Refresh-ProfileList
    Set-Status "Created profile: $safeName"
}

function Remove-ZaloProfile {
    param([string]$Name)

    if (-not $Name) { return }

    if (Is-ProfileRunning $Name) {
        Show-ErrorBox "Profile is running. Close Zalo before deleting: $Name"
        return
    }

    $message = "Delete profile '$Name'?`n`nThis will remove local data stored under:`n$Global:ProfileRoot"
    $confirm = [System.Windows.MessageBox]::Show($message, $Global:AppName, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $profilePath = Get-ProfilePath $Name
    if (Test-Path -LiteralPath $profilePath) {
        Remove-Item -LiteralPath $profilePath -Recurse -Force
    }

    Refresh-ProfileList
    Set-Status "Deleted profile: $Name"
}

function Start-ZaloProfile {
    param([string]$Name)

    $zaloExe = Find-ZaloExe
    if (-not $zaloExe) {
        Show-ErrorBox "Zalo.exe was not found. Please install Zalo PC first."
        return
    }

    $safeName = Get-SafeName $Name
    if (-not $safeName) { return }

    $profilePath = Get-ProfilePath $safeName
    $roamingPath = Join-Path $profilePath "AppData\Roaming"
    $localPath = Join-Path $profilePath "AppData\Local"
    $zaloDataPath = Join-Path $roamingPath "ZaloData"

    Ensure-Directory $profilePath
    Ensure-Directory $roamingPath
    Ensure-Directory $localPath
    Ensure-Directory $zaloDataPath

    $storageJson = Join-Path $zaloDataPath "storage.json"
    if (-not (Test-Path -LiteralPath $storageJson)) {
        $deviceId = [System.Guid]::NewGuid().ToString().ToUpper()
        $storage = @{ deviceId = $deviceId } | ConvertTo-Json -Compress
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($storageJson, $storage, $utf8NoBom)
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $zaloExe
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = Split-Path -Parent $zaloExe
    $psi.EnvironmentVariables["USERPROFILE"] = $profilePath
    $psi.EnvironmentVariables["APPDATA"] = $roamingPath
    $psi.EnvironmentVariables["LOCALAPPDATA"] = $localPath

    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
        if ($null -ne $proc) {
            $proc.Id | Set-Content -LiteralPath (Join-Path $profilePath "pid.txt") -Force -Encoding ASCII
            Set-Status "Opened Zalo profile: $safeName"
        }
    } catch {
        Show-ErrorBox "Cannot open Zalo profile '$safeName'.`n`n$($_.Exception.Message)"
    }
}

function Stop-AllZalo {
    $confirm = [System.Windows.MessageBox]::Show("Close all running Zalo.exe processes?", $Global:AppName, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    Get-Process "Zalo" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Set-Status "Requested to close all Zalo.exe processes."
    Refresh-ProfileList
}

function Export-ZaloProfile {
    param([string]$Name)

    if (-not $Name) { return }

    $profilePath = Get-ProfilePath $Name
    if (-not (Test-Path -LiteralPath $profilePath)) { return }

    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = "Export profile"
    $dialog.Filter = "Koha Zalo Profile (*.kzp)|*.kzp|Zip file (*.zip)|*.zip"
    $dialog.FileName = "$Name-$(Get-Date -Format 'yyyyMMdd-HHmmss').kzp"

    if ($dialog.ShowDialog() -eq $true) {
        try {
            Compress-Archive -Path (Join-Path $profilePath "*") -DestinationPath $dialog.FileName -Force
            Show-Info "Exported profile:`n$($dialog.FileName)"
        } catch {
            Show-ErrorBox "Cannot export profile.`n`n$($_.Exception.Message)"
        }
    }
}

function Import-ZaloProfile {
    $open = New-Object Microsoft.Win32.OpenFileDialog
    $open.Title = "Import profile"
    $open.Filter = "Koha Zalo Profile (*.kzp;*.zip)|*.kzp;*.zip|All files (*.*)|*.*"

    if ($open.ShowDialog() -ne $true) { return }

    $name = [Microsoft.VisualBasic.Interaction]::InputBox("Enter imported profile name:", $Global:AppName, "Imported")
    $safeName = Get-SafeName $name
    if (-not $safeName) { return }

    $dest = Get-ProfilePath $safeName
    if (Test-Path -LiteralPath $dest) {
        Show-ErrorBox "Profile already exists: $safeName"
        return
    }

    try {
        Ensure-Directory $dest
        Expand-Archive -Path $open.FileName -DestinationPath $dest -Force
        Refresh-ProfileList
        Show-Info "Imported profile: $safeName"
    } catch {
        if (Test-Path -LiteralPath $dest) {
            Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue
        }
        Show-ErrorBox "Cannot import profile.`n`n$($_.Exception.Message)"
    }
}

function Create-DesktopShortcut {
    param([string]$Name)

    if (-not $Name) { return }

    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "$Name.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$Global:ScriptPath`" -LaunchProfile `"$Name`""
        $shortcut.WorkingDirectory = $Global:AppDir
        $shortcut.WindowStyle = 7
        $shortcut.Description = "Open $Name with $Global:AppName"
        $shortcut.Save()
        Show-Info "Created desktop shortcut for profile: $Name"
    } catch {
        Show-ErrorBox "Cannot create shortcut.`n`n$($_.Exception.Message)"
    }
}

function Open-ProfilePowerShell {
    param([string]$Name)

    $safeName = Get-SafeName $Name
    if (-not $safeName) { return }

    $profilePath = Get-ProfilePath $safeName
    $roamingPath = Join-Path $profilePath "AppData\Roaming"
    $localPath = Join-Path $profilePath "AppData\Local"

    Ensure-Directory $profilePath
    Ensure-Directory $roamingPath
    Ensure-Directory $localPath

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.UseShellExecute = $false
        $psi.WorkingDirectory = $profilePath
        $cmd = "`$host.UI.RawUI.WindowTitle = 'PowerShell - $safeName'; Write-Host 'Koha Zalo Multi profile: $safeName'; Write-Host 'USERPROFILE=' `$env:USERPROFILE; Write-Host 'APPDATA=' `$env:APPDATA; Write-Host 'LOCALAPPDATA=' `$env:LOCALAPPDATA"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        $psi.Arguments = "-NoExit -NoProfile -EncodedCommand $encoded"
        $psi.EnvironmentVariables["USERPROFILE"] = $profilePath
        $psi.EnvironmentVariables["APPDATA"] = $roamingPath
        $psi.EnvironmentVariables["LOCALAPPDATA"] = $localPath

        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Set-Status "Opened PowerShell for profile: $safeName"
    } catch {
        Show-ErrorBox "Cannot open PowerShell for profile '$safeName'.`n`n$($_.Exception.Message)"
    }
}

# =============================
# UPDATE ACTIONS
# =============================
function Get-RemoteVersion {
    $url = "$($Global:RemoteBase)/version.txt"
    try {
        return (Invoke-RestMethod -Uri $url -UseBasicParsing -TimeoutSec 10).Trim()
    } catch {
        return ""
    }
}

function Compare-VersionString {
    param([string]$Remote, [string]$Local)
    try {
        $remoteVersion = [version]$Remote
        $localVersion = [version]$Local
        return ($remoteVersion -gt $localVersion)
    } catch {
        return $false
    }
}

function Install-SelfUpdate {
    param([switch]$SilentCheck)

    $remoteVersion = Get-RemoteVersion
    if (-not $remoteVersion) {
        if (-not $SilentCheck) {
            Show-ErrorBox "Cannot check version from GitHub.`n`nCreate version.txt in repo: $($Global:Owner)/$($Global:Repo)"
        }
        return
    }

    if (-not (Compare-VersionString -Remote $remoteVersion -Local $Global:Version)) {
        if (-not $SilentCheck) {
            Show-Info "You are using the latest version.`n`nCurrent version: $Global:Version"
        }
        return
    }

    $message = "New version found: $remoteVersion`nCurrent version: $Global:Version`n`nUpdate now?"
    $confirm = [System.Windows.MessageBox]::Show($message, $Global:AppName, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $remoteScriptUrl = "$($Global:RemoteBase)/KohaZaloMulti.ps1"
    $tempScript = Join-Path $env:TEMP "KohaZaloMulti.new.ps1"
    $backupScript = "$Global:ScriptPath.bak"

    try {
        Invoke-WebRequest -Uri $remoteScriptUrl -OutFile $tempScript -UseBasicParsing -TimeoutSec 30
        $downloaded = Get-Content -LiteralPath $tempScript -Raw -Encoding UTF8

        if ($downloaded.Length -lt 5000 -or $downloaded -notmatch "Koha Zalo Multi") {
            throw "Downloaded file does not look valid."
        }

        Copy-Item -LiteralPath $Global:ScriptPath -Destination $backupScript -Force
        Copy-Item -LiteralPath $tempScript -Destination $Global:ScriptPath -Force
        Remove-Item -LiteralPath $tempScript -Force -ErrorAction SilentlyContinue

        Show-Info "Updated to version $remoteVersion.`nThe app will restart now."
        if ($null -ne $Global:Window) { $Global:Window.Close() }
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Global:ScriptPath`"" -WorkingDirectory $Global:AppDir
    } catch {
        Show-ErrorBox "Update failed.`n`n$($_.Exception.Message)"
    }
}

# =============================
# UI
# =============================
function New-Button {
    param(
        [string]$Text,
        [scriptblock]$OnClick,
        [int]$Width = 120
    )

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $Text
    $btn.Width = $Width
    $btn.Height = 36
    $btn.Margin = "4"
    $btn.Padding = "10,4"
    $btn.Add_Click($OnClick)
    return $btn
}

function Get-SelectedProfileName {
    if ($null -eq $Global:ProfileList) { return "" }
    if ($null -eq $Global:ProfileList.SelectedItem) { return "" }
    return [string]$Global:ProfileList.SelectedItem.Tag
}

function Refresh-ProfileList {
    if ($null -eq $Global:ProfileList) { return }

    $Global:ProfileList.Items.Clear()
    $profiles = Get-Profiles

    foreach ($profile in $profiles) {
        $running = Is-ProfileRunning $profile.Name
        $status = if ($running) { "Running" } else { "Ready" }

        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Tag = $profile.Name
        $item.Content = "$($profile.Name)    [$status]"
        $item.Padding = "10"
        $item.Margin = "0,0,0,6"
        $Global:ProfileList.Items.Add($item) | Out-Null
    }

    Set-Status "Profiles: $($profiles.Count) | Folder: $Global:ProfileRoot"
}

function Start-AutoUpdateCheck {
    try {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2)
        $timer.Add_Tick({
            $this.Stop()
            Set-Status "Checking for updates..."
            Install-SelfUpdate -SilentCheck
            Set-Status "Ready"
        })
        $timer.Start()
    } catch {
        # Ignore auto update check errors.
    }
}

function Build-UI {
    $Global:Window = New-Object System.Windows.Window
    $Global:Window.Title = "$Global:AppName v$Global:Version"
    $Global:Window.Width = 790
    $Global:Window.Height = 560
    $Global:Window.MinWidth = 720
    $Global:Window.MinHeight = 480
    $Global:Window.WindowStartupLocation = "CenterScreen"

    $root = New-Object System.Windows.Controls.Grid
    $root.Margin = "16"
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "*" }))
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))

    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = $Global:AppName
    $title.FontSize = 24
    $title.FontWeight = "Bold"
    $title.Margin = "0,0,0,4"
    [System.Windows.Controls.Grid]::SetRow($title, 0)
    $root.Children.Add($title) | Out-Null

    $subtitle = New-Object System.Windows.Controls.TextBlock
    $subtitle.Text = "Run multiple Zalo Desktop profiles without creating extra Windows users."
    $subtitle.Margin = "0,34,0,12"
    $subtitle.Opacity = 0.75
    [System.Windows.Controls.Grid]::SetRow($subtitle, 0)
    $root.Children.Add($subtitle) | Out-Null

    $toolbar = New-Object System.Windows.Controls.WrapPanel
    $toolbar.Margin = "0,8,0,12"
    [System.Windows.Controls.Grid]::SetRow($toolbar, 1)

    $toolbar.Children.Add((New-Button "Add profile" {
        $name = [Microsoft.VisualBasic.Interaction]::InputBox("Enter profile name:", $Global:AppName, "Zalo 1")
        if ($name) { New-ZaloProfile $name }
    })) | Out-Null

    $toolbar.Children.Add((New-Button "Open Zalo" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox "Please select a profile."; return }
        Start-ZaloProfile $name
        Refresh-ProfileList
    })) | Out-Null

    $toolbar.Children.Add((New-Button "PowerShell" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox "Please select a profile."; return }
        Open-ProfilePowerShell $name
    })) | Out-Null

    $toolbar.Children.Add((New-Button "Shortcut" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox "Please select a profile."; return }
        Create-DesktopShortcut $name
    })) | Out-Null

    $toolbar.Children.Add((New-Button "Export" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox "Please select a profile."; return }
        Export-ZaloProfile $name
    })) | Out-Null

    $toolbar.Children.Add((New-Button "Import" {
        Import-ZaloProfile
    })) | Out-Null

    $toolbar.Children.Add((New-Button "Delete" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox "Please select a profile."; return }
        Remove-ZaloProfile $name
    })) | Out-Null

    $toolbar.Children.Add((New-Button "Close all" {
        Stop-AllZalo
    })) | Out-Null

    $toolbar.Children.Add((New-Button "Update" {
        Install-SelfUpdate
    })) | Out-Null

    $root.Children.Add($toolbar) | Out-Null

    $Global:ProfileList = New-Object System.Windows.Controls.ListBox
    $Global:ProfileList.Margin = "0,0,0,12"
    $Global:ProfileList.FontSize = 15
    $Global:ProfileList.Add_MouseDoubleClick({
        $name = Get-SelectedProfileName
        if ($name) {
            Start-ZaloProfile $name
            Refresh-ProfileList
        }
    })
    [System.Windows.Controls.Grid]::SetRow($Global:ProfileList, 2)
    $root.Children.Add($Global:ProfileList) | Out-Null

    $bottom = New-Object System.Windows.Controls.DockPanel
    [System.Windows.Controls.Grid]::SetRow($bottom, 3)

    $Global:StatusText = New-Object System.Windows.Controls.TextBlock
    $Global:StatusText.Text = "Ready"
    $Global:StatusText.Opacity = 0.72
    $Global:StatusText.TextWrapping = "Wrap"
    [System.Windows.Controls.DockPanel]::SetDock($Global:StatusText, "Left")
    $bottom.Children.Add($Global:StatusText) | Out-Null

    $root.Children.Add($bottom) | Out-Null
    $Global:Window.Content = $root

    Refresh-ProfileList
    Start-AutoUpdateCheck
    $Global:Window.ShowDialog() | Out-Null
}

# =============================
# ENTRY
# =============================
Load-Config
Save-Config

if ($LaunchProfile) {
    Start-ZaloProfile $LaunchProfile
    exit
}

if ($CheckUpdateOnly) {
    Install-SelfUpdate
    exit
}

Build-UI
