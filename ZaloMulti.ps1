# ZaloMulti - Personal Multi Profile Launcher
# Version: 1.2.5
# Author: Nguyễn Lê Khánh Hòa
# Website: https://koha.io.vn
#
# Build this script into ZaloMulti.exe.
# Send only ZaloMulti.exe to users.
# Auto-update downloads release/ZaloMulti.exe from GitHub and replaces the running exe.

param(
    [string]$LaunchProfile = "",
    [switch]$CheckUpdateOnly
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

function Get-AppBaseDirectory {
    try {
        if ($PSScriptRoot) { return $PSScriptRoot }
        if ($MyInvocation.MyCommand.Path) { return (Split-Path -Parent $MyInvocation.MyCommand.Path) }

        $processPath = ""
        try { $processPath = [Environment]::ProcessPath } catch { }
        if (-not $processPath) {
            try { $processPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName } catch { }
        }
        if ($processPath) {
            $dir = Split-Path -Parent $processPath
            if ($dir) { return $dir }
        }

        try {
            $baseDir = [System.AppContext]::BaseDirectory
            if ($baseDir) { return $baseDir.TrimEnd('\') }
        } catch { }
    } catch { }

    return [Environment]::CurrentDirectory
}

# =============================
# CONFIG
# =============================
$Global:AppName = "ZaloMulti"
$Global:Version = "1.2.5"
$Global:AuthorName = "Nguyễn Lê Khánh Hòa"
$Global:WebsiteUrl = "https://koha.io.vn"

# GitHub repo:
# https://github.com/koha2002/MultiZalo
$Global:Owner = "koha2002"
$Global:Repo = "MultiZalo"
$Global:Branch = "main"

$Global:ExeName = "ZaloMulti.exe"
$Global:RemoteBase = "https://raw.githubusercontent.com/$($Global:Owner)/$($Global:Repo)/$($Global:Branch)"
$Global:RemoteVersionUrl = "$($Global:RemoteBase)/version.txt"
$Global:RemoteExeUrl = "$($Global:RemoteBase)/release/$($Global:ExeName)"

$Global:AppDir = Get-AppBaseDirectory
$Global:DataRoot = Join-Path $env:LOCALAPPDATA "ZaloMulti"
$Global:ProfileRoot = Join-Path $Global:DataRoot "Profiles"
$Global:ConfigFile = Join-Path $Global:DataRoot "config.json"

$Global:Language = "vi"
$Global:Theme = "light"

$Global:Window = $null
$Global:ProfileList = $null
$Global:StatusText = $null
$Global:TabControl = $null

$Global:TextControls = @{}
$Global:MainControls = @{}

# =============================
# I18N
# =============================
$Global:I18n = @{
    vi = @{
        app_subtitle = "Chạy nhiều Zalo Desktop cùng lúc, không cần tạo thêm user Windows."
        author_line = "Tác giả: {0}"
        website_line = "Website: {0}"
        tab_profiles = "Profile"
        tab_tools = "Công cụ"
        tab_settings = "Cài đặt"
        add_profile = "Thêm profile"
        open_zalo = "Mở Zalo"
        open_folder = "Mở thư mục"
        delete = "Xóa"
        close_all = "Đóng tất cả"
        website = "Mở website"
        tools_title = "Công cụ profile"
        backup_profile = "Sao lưu profile"
        import_profile = "Nhập profile"
        create_shortcut = "Tạo shortcut"
        check_update = "Kiểm tra cập nhật"
        settings_title = "Cài đặt giao diện"
        language = "Ngôn ngữ"
        theme = "Giao diện"
        light = "Sáng"
        dark = "Tối"
        save_settings = "Lưu cài đặt"
        profile_prompt = "Nhập tên profile:"
        profile_default = "Zalo 1"
        select_profile = "Hãy chọn một profile."
        empty_profile = "Tên profile không được để trống."
        exists_profile = "Profile đã tồn tại: {0}"
        created_profile = "Đã tạo profile: {0}"
        deleted_profile = "Đã xóa profile: {0}"
        opened_zalo = "Đã mở Zalo: {0}"
        closed_all = "Đã đóng tất cả tiến trình Zalo."
        opened_folder = "Đã mở thư mục profile: {0}"
        shortcut_created = "Đã tạo shortcut ngoài Desktop cho profile: {0}"
        exported_profile = "Đã sao lưu profile:`n{0}"
        imported_profile = "Đã nhập profile: {0}"
        ready = "Sẵn sàng"
        checking_update = "Đang kiểm tra cập nhật..."
        downloading_update = "Đang tải bản cập nhật..."
        latest_version = "Bạn đang dùng phiên bản mới nhất.`n`nPhiên bản hiện tại: {0}"
        update_found = "Có bản cập nhật mới: {0}`nPhiên bản hiện tại: {1}`n`nCập nhật ngay?"
        update_downloaded = "Đã tải bản cập nhật.`nỨng dụng sẽ tự khởi động lại."
        update_failed = "Cập nhật thất bại.`n`n{0}"
        cannot_check = "Không kiểm tra được phiên bản từ GitHub.`n`nURL:`n{0}"
        cannot_open_website = "Không thể mở website.`n`n{0}"
        cannot_find_zalo = "Không tìm thấy Zalo.exe. Hãy cài Zalo PC trước."
        cannot_open_zalo = "Không thể mở Zalo cho profile '{0}'.`n`n{1}"
        cannot_open_folder = "Không thể mở thư mục profile '{0}'.`n`n{1}"
        cannot_export = "Không thể sao lưu profile.`n`n{0}"
        cannot_import = "Không thể nhập profile.`n`n{0}"
        cannot_shortcut = "Không thể tạo shortcut.`n`n{0}"
        delete_confirm = "Xóa profile '{0}'?`n`nThao tác này sẽ xóa dữ liệu local trong:`n{1}"
        close_all_confirm = "Đóng tất cả tiến trình Zalo.exe đang chạy?"
        running = "Đang chạy"
        idle = "Sẵn sàng"
        profiles_status = "Profiles: {0} | Thư mục: {1}"
        saved_settings = "Đã lưu cài đặt."
        auto_update_exe_only = "Auto-update chỉ hoạt động ở bản EXE đã build.`n`nHãy build ZaloMulti.exe trước khi test update."
        choose_import_name = "Đặt tên cho profile nhập vào:"
        imported_default = "Đã nhập"
        profile_running_delete = "Profile đang chạy. Hãy đóng Zalo trước khi xóa: {0}"
        backup_note = "Sao lưu/Nhập dùng để chuyển profile sang máy khác hoặc khôi phục khi cần."
        choose_profile = "Chọn profile"
    }
    en = @{
        app_subtitle = "Run multiple Zalo Desktop profiles without creating extra Windows users."
        author_line = "Author: {0}"
        website_line = "Website: {0}"
        tab_profiles = "Profiles"
        tab_tools = "Tools"
        tab_settings = "Settings"
        add_profile = "Add profile"
        open_zalo = "Open Zalo"
        open_folder = "Open folder"
        delete = "Delete"
        close_all = "Close all"
        website = "Open website"
        tools_title = "Profile tools"
        backup_profile = "Export profile"
        import_profile = "Import profile"
        create_shortcut = "Create shortcut"
        check_update = "Check update"
        settings_title = "Appearance settings"
        language = "Language"
        theme = "Theme"
        light = "Light"
        dark = "Dark"
        save_settings = "Save settings"
        profile_prompt = "Enter profile name:"
        profile_default = "Zalo 1"
        select_profile = "Please select a profile."
        empty_profile = "Profile name cannot be empty."
        exists_profile = "Profile already exists: {0}"
        created_profile = "Created profile: {0}"
        deleted_profile = "Deleted profile: {0}"
        opened_zalo = "Opened Zalo: {0}"
        closed_all = "Closed all Zalo processes."
        opened_folder = "Opened profile folder: {0}"
        shortcut_created = "Created desktop shortcut for profile: {0}"
        exported_profile = "Exported profile:`n{0}"
        imported_profile = "Imported profile: {0}"
        ready = "Ready"
        checking_update = "Checking for updates..."
        downloading_update = "Downloading update..."
        latest_version = "You are using the latest version.`n`nCurrent version: {0}"
        update_found = "New version found: {0}`nCurrent version: {1}`n`nUpdate now?"
        update_downloaded = "Update downloaded.`nThe app will restart now."
        update_failed = "Update failed.`n`n{0}"
        cannot_check = "Cannot check version from GitHub.`n`nURL:`n{0}"
        cannot_open_website = "Cannot open website.`n`n{0}"
        cannot_find_zalo = "Zalo.exe was not found. Please install Zalo PC first."
        cannot_open_zalo = "Cannot open Zalo profile '{0}'.`n`n{1}"
        cannot_open_folder = "Cannot open profile folder '{0}'.`n`n{1}"
        cannot_export = "Cannot export profile.`n`n{0}"
        cannot_import = "Cannot import profile.`n`n{0}"
        cannot_shortcut = "Cannot create shortcut.`n`n{0}"
        delete_confirm = "Delete profile '{0}'?`n`nThis will remove local data stored under:`n{1}"
        close_all_confirm = "Close all running Zalo.exe processes?"
        running = "Running"
        idle = "Ready"
        profiles_status = "Profiles: {0} | Folder: {1}"
        saved_settings = "Settings saved."
        auto_update_exe_only = "Auto-update works only in the built exe.`n`nBuild ZaloMulti.exe first, then test update."
        choose_import_name = "Enter imported profile name:"
        imported_default = "Imported"
        profile_running_delete = "Profile is running. Close Zalo before deleting: {0}"
        backup_note = "Export/Import is for moving profiles to another PC or restoring them later."
        choose_profile = "Choose profile"
    }
}

function T {
    param(
        [string]$Key,
        [object[]]$Values = @()
    )

    $dict = $Global:I18n[$Global:Language]
    if (-not $dict.ContainsKey($Key)) {
        $dict = $Global:I18n["en"]
    }

    $value = [string]$dict[$Key]
    if ($null -ne $Values -and $Values.Count -gt 0) {
        return [string]::Format($value, $Values)
    }

    return $value
}

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

function Open-Website {
    try {
        Start-Process $Global:WebsiteUrl
    } catch {
        Show-ErrorBox (T "cannot_open_website" @($_.Exception.Message))
    }
}

function Get-RunningAppPath {
    try {
        $p = ""
        try { $p = [Environment]::ProcessPath } catch { }
        if (-not $p) {
            try { $p = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName } catch { }
        }
        if (-not $p -and $MyInvocation.MyCommand.Path) {
            $p = $MyInvocation.MyCommand.Path
        }
        return [string]$p
    } catch {
        return ""
    }
}

function Test-IsPackagedExe {
    $path = Get-RunningAppPath
    if (-not $path) { return $false }

    $fileName = [System.IO.Path]::GetFileName($path).ToLowerInvariant()
    if ($fileName -eq "powershell.exe" -or $fileName -eq "pwsh.exe" -or $fileName -eq "powershell_ise.exe") {
        return $false
    }

    return ($path.ToLowerInvariant().EndsWith(".exe"))
}

function Load-Config {
    Ensure-Directory $Global:DataRoot
    Ensure-Directory $Global:ProfileRoot

    if (Test-Path -LiteralPath $Global:ConfigFile) {
        try {
            $cfg = Get-Content -LiteralPath $Global:ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($cfg.ProfileRoot) { $Global:ProfileRoot = [string]$cfg.ProfileRoot }
            if ($cfg.Language) { $Global:Language = [string]$cfg.Language }
            if ($cfg.Theme) { $Global:Theme = [string]$cfg.Theme }
        } catch { }
    }

    if ($Global:Language -notin @("vi", "en")) { $Global:Language = "vi" }
    if ($Global:Theme -notin @("light", "dark")) { $Global:Theme = "light" }

    Ensure-Directory $Global:ProfileRoot
}

function Save-Config {
    Ensure-Directory $Global:DataRoot
    $cfg = [ordered]@{
        AppName = $Global:AppName
        Version = $Global:Version
        AuthorName = $Global:AuthorName
        WebsiteUrl = $Global:WebsiteUrl
        ProfileRoot = $Global:ProfileRoot
        Language = $Global:Language
        Theme = $Global:Theme
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

# =============================
# THEME
# =============================
function Get-ThemeColors {
    if ($Global:Theme -eq "dark") {
        return @{
            WindowBg = "#111827"
            PanelBg = "#1F2937"
            Text = "#F9FAFB"
            Muted = "#D1D5DB"
            ButtonBg = "#374151"
            ButtonText = "#F9FAFB"
            Border = "#4B5563"
            ListBg = "#111827"
            ListItemBg = "#111827"
            Accent = "#60A5FA"
        }
    }

    return @{
        WindowBg = "#F7F7F8"
        PanelBg = "#FFFFFF"
        Text = "#111827"
        Muted = "#4B5563"
        ButtonBg = "#E5E7EB"
        ButtonText = "#111827"
        Border = "#D1D5DB"
        ListBg = "#FFFFFF"
        ListItemBg = "#FFFFFF"
        Accent = "#2563EB"
    }
}

function Apply-Theme {
    if ($null -eq $Global:Window) { return }

    $c = Get-ThemeColors
    $Global:Window.Background = $c.WindowBg

    foreach ($key in $Global:TextControls.Keys) {
        $ctrl = $Global:TextControls[$key]
        if ($ctrl -is [System.Windows.Controls.TextBlock]) {
            if ($key -like "muted_*") {
                $ctrl.Foreground = $c.Muted
            } elseif ($key -like "link_*") {
                $ctrl.Foreground = $c.Accent
            } else {
                $ctrl.Foreground = $c.Text
            }
        }
    }

    foreach ($key in $Global:MainControls.Keys) {
        $ctrl = $Global:MainControls[$key]

        if ($ctrl -is [System.Windows.Controls.Button]) {
            $ctrl.Background = $c.ButtonBg
            $ctrl.Foreground = $c.ButtonText
            $ctrl.BorderBrush = $c.Border
        }

        if ($ctrl -is [System.Windows.Controls.ComboBox]) {
            # Keep ComboBox readable in dark mode.
            # Windows renders the dropdown popup with a light background by default,
            # so using white foreground makes items look invisible.
            $ctrl.Background = "White"
            $ctrl.Foreground = "Black"
            $ctrl.BorderBrush = "#D1D5DB"
        }

        if ($ctrl -is [System.Windows.Controls.ListBox]) {
            $ctrl.Background = $c.ListBg
            $ctrl.Foreground = $c.Text
            $ctrl.BorderBrush = $c.Border
        }

        if ($ctrl -is [System.Windows.Controls.TabControl]) {
            $ctrl.Background = $c.WindowBg
            $ctrl.Foreground = $c.Text
        }

        if ($ctrl -is [System.Windows.Controls.StackPanel]) {
            $ctrl.Background = $c.WindowBg
        }
    }
}

function Apply-Language {
    if ($null -eq $Global:Window) { return }

    $Global:Window.Title = "$Global:AppName v$Global:Version"

    if ($Global:TextControls.ContainsKey("author")) {
        $Global:TextControls["author"].Text = T "author_line" @($Global:AuthorName)
    }

    if ($Global:TextControls.ContainsKey("website_line")) {
        $Global:TextControls["website_line"].Text = T "website_line" @($Global:WebsiteUrl)
    }

    if ($Global:TextControls.ContainsKey("tools_title")) {
        $Global:TextControls["tools_title"].Text = T "tools_title"
    }

    if ($Global:TextControls.ContainsKey("tools_profile_label")) {
        $Global:TextControls["tools_profile_label"].Text = T "choose_profile"
    }

    if ($Global:TextControls.ContainsKey("backup_note")) {
        $Global:TextControls["backup_note"].Text = T "backup_note"
    }

    if ($Global:TextControls.ContainsKey("settings_title")) {
        $Global:TextControls["settings_title"].Text = T "settings_title"
    }

    if ($Global:TextControls.ContainsKey("language_label")) {
        $Global:TextControls["language_label"].Text = T "language"
    }

    if ($Global:TextControls.ContainsKey("theme_label")) {
        $Global:TextControls["theme_label"].Text = T "theme"
    }

    if ($Global:TabControl) {
        $Global:TabControl.Items[0].Header = T "tab_profiles"
        $Global:TabControl.Items[1].Header = T "tab_tools"
        $Global:TabControl.Items[2].Header = T "tab_settings"
    }

    $map = @{
        add_profile = "add_profile"
        open_zalo = "open_zalo"
        open_folder = "open_folder"
        delete = "delete"
        close_all = "close_all"
        website_button = "website"
        backup_profile = "backup_profile"
        import_profile = "import_profile"
        create_shortcut = "create_shortcut"
        check_update = "check_update"
        save_settings = "save_settings"
    }

    foreach ($name in $map.Keys) {
        if ($Global:MainControls.ContainsKey($name)) {
            $Global:MainControls[$name].Content = T $map[$name]
        }
    }

    if ($Global:MainControls.ContainsKey("language_combo")) {
        $combo = $Global:MainControls["language_combo"]
        $combo.Items.Clear()
        [void]$combo.Items.Add((New-ComboItem "Tiếng Việt" "vi"))
        [void]$combo.Items.Add((New-ComboItem "English" "en"))
        $combo.SelectedIndex = if ($Global:Language -eq "vi") { 0 } else { 1 }
    }

    if ($Global:MainControls.ContainsKey("theme_combo")) {
        $combo = $Global:MainControls["theme_combo"]
        $combo.Items.Clear()
        [void]$combo.Items.Add((New-ComboItem (T "light") "light"))
        [void]$combo.Items.Add((New-ComboItem (T "dark") "dark"))
        $combo.SelectedIndex = if ($Global:Theme -eq "light") { 0 } else { 1 }
    }

    Refresh-ProfileList
}

# =============================
# PID TRACKING
# =============================
function Get-ZaloProcessIds {
    return @(Get-Process "Zalo" -ErrorAction SilentlyContinue | ForEach-Object { [int]$_.Id })
}

function Save-ProfilePids {
    param(
        [string]$Name,
        [int[]]$Pids
    )

    $profilePath = Get-ProfilePath $Name
    Ensure-Directory $profilePath

    $pidFile = Join-Path $profilePath "pids.json"
    $payload = [ordered]@{
        Profile = $Name
        Pids = @($Pids | Sort-Object -Unique)
        UpdatedAt = (Get-Date).ToString("s")
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($pidFile, ($payload | ConvertTo-Json -Depth 5), $utf8NoBom)
}

function Get-ProfilePids {
    param([string]$Name)

    $profilePath = Get-ProfilePath $Name
    $pidJsonFile = Join-Path $profilePath "pids.json"
    $result = @()

    if (Test-Path -LiteralPath $pidJsonFile) {
        try {
            $data = Get-Content -LiteralPath $pidJsonFile -Raw -ErrorAction Stop | ConvertFrom-Json
            if ($data.Pids) {
                $result += @($data.Pids | ForEach-Object { [int]$_ })
            }
        } catch { }
    }

    return @($result | Sort-Object -Unique)
}

function Is-ProfileRunning {
    param([string]$Name)

    $pids = @(Get-ProfilePids $Name)
    if ($pids.Count -eq 0) { return $false }

    foreach ($pidValue in $pids) {
        try {
            $proc = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
            if ($proc -and $proc.ProcessName -like "Zalo*") {
                return $true
            }
        } catch { }
    }

    return $false
}

function Clear-DeadProfilePids {
    param([string]$Name)

    $pids = @(Get-ProfilePids $Name)
    if ($pids.Count -eq 0) { return }

    $alive = @()
    foreach ($pidValue in $pids) {
        try {
            $proc = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
            if ($proc -and $proc.ProcessName -like "Zalo*") {
                $alive += [int]$pidValue
            }
        } catch { }
    }

    Save-ProfilePids -Name $Name -Pids $alive
}

# =============================
# SELECTION
# =============================
function Get-SelectedProfileName {
    if ($null -eq $Global:ProfileList) { return "" }

    $selected = $Global:ProfileList.SelectedItem

    if ($null -eq $selected) {
        if ($Global:ProfileList.Items.Count -eq 1) {
            $Global:ProfileList.SelectedIndex = 0
            $selected = $Global:ProfileList.SelectedItem
        } else {
            return ""
        }
    }

    if ($selected -is [System.Windows.Controls.ListBoxItem]) {
        if ($selected.Tag) { return [string]$selected.Tag }
        if ($selected.Content) {
            $content = [string]$selected.Content
            return ($content -replace "\s+\[.*?\]\s*$", "").Trim()
        }
    }

    return [string]$selected
}

function Update-ToolsProfileCombo {
    if (-not $Global:MainControls.ContainsKey("tools_profile_combo")) { return }

    $combo = $Global:MainControls["tools_profile_combo"]
    $current = Get-ComboSelectedValue $combo

    $combo.Items.Clear()
    $profiles = Get-Profiles

    $selectIndex = -1
    $i = 0

    foreach ($profile in $profiles) {
        [void]$combo.Items.Add((New-ComboItem $profile.Name $profile.Name))
        if ($current -and $profile.Name -eq $current) {
            $selectIndex = $i
        }
        $i++
    }

    if ($selectIndex -ge 0) {
        $combo.SelectedIndex = $selectIndex
    } elseif ($combo.Items.Count -gt 0) {
        $combo.SelectedIndex = 0
    }
}

function Get-ToolProfileName {
    if ($Global:MainControls.ContainsKey("tools_profile_combo")) {
        $combo = $Global:MainControls["tools_profile_combo"]
        $value = Get-ComboSelectedValue $combo
        if ($value) { return $value }
    }

    return Get-SelectedProfileName
}

# =============================
# PROFILE ACTIONS
# =============================
function New-ZaloProfile {
    param([string]$Name)

    $safeName = Get-SafeName $Name
    if (-not $safeName) {
        Show-ErrorBox (T "empty_profile")
        return
    }

    $profilePath = Get-ProfilePath $safeName
    if (Test-Path -LiteralPath $profilePath) {
        Show-ErrorBox (T "exists_profile" @($safeName))
        return
    }

    Ensure-Directory $profilePath
    Ensure-Directory (Join-Path $profilePath "AppData\Roaming")
    Ensure-Directory (Join-Path $profilePath "AppData\Local")

    Refresh-ProfileList
    Set-Status (T "created_profile" @($safeName))
}

function Remove-ZaloProfile {
    param([string]$Name)

    if (-not $Name) { return }

    if (Is-ProfileRunning $Name) {
        Show-ErrorBox (T "profile_running_delete" @($Name))
        return
    }

    $message = T "delete_confirm" @($Name, $Global:ProfileRoot)
    $confirm = [System.Windows.MessageBox]::Show($message, $Global:AppName, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $profilePath = Get-ProfilePath $Name
    if (Test-Path -LiteralPath $profilePath) {
        Remove-Item -LiteralPath $profilePath -Recurse -Force
    }

    Refresh-ProfileList
    Set-Status (T "deleted_profile" @($Name))
}

function Start-ZaloProfile {
    param([string]$Name)

    $zaloExe = Find-ZaloExe
    if (-not $zaloExe) {
        Show-ErrorBox (T "cannot_find_zalo")
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
        $beforePids = @(Get-ZaloProcessIds)
        $proc = [System.Diagnostics.Process]::Start($psi)

        Start-Sleep -Milliseconds 2500

        $afterPids = @(Get-ZaloProcessIds)
        $newPids = @($afterPids | Where-Object { $beforePids -notcontains $_ })

        if ($proc) {
            $newPids += [int]$proc.Id
        }

        $newPids = @($newPids | Sort-Object -Unique)

        if ($newPids.Count -eq 0 -and $proc) {
            $newPids = @([int]$proc.Id)
        }

        Save-ProfilePids -Name $safeName -Pids $newPids
        Set-Status (T "opened_zalo" @($safeName))
        Refresh-ProfileList
    } catch {
        Show-ErrorBox (T "cannot_open_zalo" @($safeName, $_.Exception.Message))
    }
}

function Stop-AllZalo {
    $confirm = [System.Windows.MessageBox]::Show((T "close_all_confirm"), $Global:AppName, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    Get-Process "Zalo" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    foreach ($profile in Get-Profiles) {
        $pidJsonFile = Join-Path $profile.FullName "pids.json"
        Remove-Item -LiteralPath $pidJsonFile -Force -ErrorAction SilentlyContinue
    }

    Set-Status (T "closed_all")
    Refresh-ProfileList
}

function Open-ProfileFolder {
    param([string]$Name)

    $safeName = Get-SafeName $Name
    if (-not $safeName) { return }

    $profilePath = Get-ProfilePath $safeName
    Ensure-Directory $profilePath

    try {
        Start-Process "explorer.exe" -ArgumentList "`"$profilePath`""
        Set-Status (T "opened_folder" @($safeName))
    } catch {
        Show-ErrorBox (T "cannot_open_folder" @($safeName, $_.Exception.Message))
    }
}

function Export-ZaloProfile {
    param([string]$Name)

    if (-not $Name) { return }

    $profilePath = Get-ProfilePath $Name
    if (-not (Test-Path -LiteralPath $profilePath)) { return }

    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = T "backup_profile"
    $dialog.Filter = "Zip file (*.zip)|*.zip"
    $dialog.DefaultExt = "zip"
    $dialog.FileName = "$Name-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"

    if ($dialog.ShowDialog() -eq $true) {
        try {
            Compress-Archive -Path (Join-Path $profilePath "*") -DestinationPath $dialog.FileName -Force
            Show-Info (T "exported_profile" @($dialog.FileName))
        } catch {
            Show-ErrorBox (T "cannot_export" @($_.Exception.Message))
        }
    }
}

function Import-ZaloProfile {
    $open = New-Object Microsoft.Win32.OpenFileDialog
    $open.Title = T "import_profile"
    $open.Filter = "Zip file (*.zip)|*.zip|All files (*.*)|*.*"

    if ($open.ShowDialog() -ne $true) { return }

    $name = [Microsoft.VisualBasic.Interaction]::InputBox((T "choose_import_name"), $Global:AppName, (T "imported_default"))
    $safeName = Get-SafeName $name
    if (-not $safeName) { return }

    $dest = Get-ProfilePath $safeName
    if (Test-Path -LiteralPath $dest) {
        Show-ErrorBox (T "exists_profile" @($safeName))
        return
    }

    try {
        Ensure-Directory $dest
        Expand-Archive -Path $open.FileName -DestinationPath $dest -Force
        Refresh-ProfileList
        Show-Info (T "imported_profile" @($safeName))
    } catch {
        if (Test-Path -LiteralPath $dest) {
            Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue
        }
        Show-ErrorBox (T "cannot_import" @($_.Exception.Message))
    }
}

function Create-ProfileShortcut {
    param([string]$Name)

    if (-not $Name) { return }

    $currentExe = Get-RunningAppPath
    if (-not (Test-IsPackagedExe)) {
        if (-not $SilentCheck) {
            Show-ErrorBox (T "auto_update_exe_only")
        }
        return
    }

    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "$Name.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $currentExe
        $shortcut.Arguments = "-LaunchProfile `"$Name`""
        $shortcut.WorkingDirectory = Split-Path -Parent $currentExe
        $shortcut.WindowStyle = 1
        $shortcut.Description = "Open $Name with $Global:AppName"
        $shortcut.IconLocation = "$currentExe,0"
        $shortcut.Save()

        Show-Info (T "shortcut_created" @($Name))
    } catch {
        Show-ErrorBox (T "cannot_shortcut" @($_.Exception.Message))
    }
}

# =============================
# EXE AUTO UPDATE
# =============================
function Get-RemoteVersion {
    try {
        return (Invoke-RestMethod -Uri $Global:RemoteVersionUrl -UseBasicParsing -TimeoutSec 10).Trim()
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

function Start-ExeReplacement {
    param(
        [string]$CurrentExe,
        [string]$NewExe
    )

    
    if (-not $CurrentExe -or -not (Test-Path -LiteralPath $CurrentExe)) {
        throw "Cannot determine current exe path for update."
    }

    if (-not $NewExe -or -not (Test-Path -LiteralPath $NewExe)) {
        throw "Downloaded update file was not found."
    }

$updaterBat = Join-Path $env:TEMP "ZaloMulti-Updater.bat"
    $appDir = Split-Path -Parent $CurrentExe

    $bat = @"
@echo off
setlocal
timeout /t 2 /nobreak > nul
taskkill /f /im "$($Global:ExeName)" > nul 2>&1
timeout /t 1 /nobreak > nul
copy /y "$NewExe" "$CurrentExe" > nul
del /f /q "$NewExe" > nul 2>&1
start "" "$CurrentExe"
del /f /q "%~f0" > nul 2>&1
"@

    $ansi = New-Object System.Text.ASCIIEncoding
    [System.IO.File]::WriteAllText($updaterBat, $bat, $ansi)

    Start-Process "cmd.exe" -ArgumentList "/c `"$updaterBat`"" -WorkingDirectory $appDir -WindowStyle Hidden
}

function Install-SelfUpdate {
    param([switch]$SilentCheck)

    $remoteVersion = Get-RemoteVersion
    if (-not $remoteVersion) {
        if (-not $SilentCheck) {
            Show-ErrorBox (T "cannot_check" @($Global:RemoteVersionUrl))
        }
        return
    }

    if (-not (Compare-VersionString -Remote $remoteVersion -Local $Global:Version)) {
        if (-not $SilentCheck) {
            Show-Info (T "latest_version" @($Global:Version))
        }
        return
    }

    $message = T "update_found" @($remoteVersion, $Global:Version)
    $confirm = [System.Windows.MessageBox]::Show($message, $Global:AppName, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    if (-not (Test-IsPackagedExe)) {
        if (-not $SilentCheck) {
            Show-ErrorBox (T "auto_update_exe_only")
        }
        return
    }

    $currentExe = Get-RunningAppPath
    if (-not $currentExe -or -not (Test-Path -LiteralPath $currentExe)) {
        if (-not $SilentCheck) {
            Show-ErrorBox "Cannot find running exe path."
        }
        return
    }

    $newExe = Join-Path $env:TEMP ("ZaloMulti-" + $remoteVersion + ".new.exe")

    try {
        Set-Status (T "downloading_update")
        Invoke-WebRequest -Uri $Global:RemoteExeUrl -OutFile $newExe -UseBasicParsing -TimeoutSec 60

        if (-not (Test-Path -LiteralPath $newExe)) {
            throw "Downloaded exe was not created."
        }

        $fileInfo = Get-Item -LiteralPath $newExe
        if ($fileInfo.Length -lt 100000) {
            throw "Downloaded exe is too small. Check release/ZaloMulti.exe on GitHub."
        }

        Show-Info (T "update_downloaded")
        Start-ExeReplacement -CurrentExe $currentExe -NewExe $newExe

        if ($null -ne $Global:Window) {
            $Global:Window.Close()
        }

        [System.Windows.Application]::Current.Shutdown()
        exit
    } catch {
        if ($newExe) {
            Remove-Item -LiteralPath $newExe -Force -ErrorAction SilentlyContinue
        }

        if (-not $SilentCheck) {
            Show-ErrorBox (T "update_failed" @($_.Exception.Message))
        } else {
            Set-Status (T "ready")
        }
    }
}

# =============================
# UI HELPERS
# =============================
function New-Button {
    param(
        [string]$Text,
        [scriptblock]$OnClick,
        [int]$Width = 130
    )

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $Text
    $btn.Width = $Width
    $btn.Height = 38
    $btn.Margin = "5"
    $btn.Padding = "10,4"
    $btn.Add_Click($OnClick)
    return $btn
}

function New-Label {
    param([string]$Text)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.Margin = "0,10,0,4"
    $tb.FontWeight = "SemiBold"
    return $tb
}

function New-ComboItem {
    param(
        [string]$Text,
        [object]$TagValue = $null
    )

    $item = New-Object System.Windows.Controls.ComboBoxItem
    $item.Content = $Text
    $item.Foreground = "Black"
    $item.Background = "White"
    if ($null -ne $TagValue) {
        $item.Tag = $TagValue
    } else {
        $item.Tag = $Text
    }
    return $item
}

function Get-ComboSelectedValue {
    param($Combo)

    if ($null -eq $Combo -or $null -eq $Combo.SelectedItem) {
        return ""
    }

    $selected = $Combo.SelectedItem
    if ($selected -is [System.Windows.Controls.ComboBoxItem]) {
        if ($selected.Tag) { return [string]$selected.Tag }
        return [string]$selected.Content
    }

    return [string]$selected
}

function Refresh-ProfileList {
    if ($null -eq $Global:ProfileList) { return }

    $selectedName = Get-SelectedProfileName

    $Global:ProfileList.Items.Clear()
    $profiles = Get-Profiles

    $indexToSelect = -1
    $i = 0

    foreach ($profile in $profiles) {
        Clear-DeadProfilePids $profile.Name

        $running = Is-ProfileRunning $profile.Name
        $status = if ($running) { T "running" } else { T "idle" }

        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Tag = $profile.Name
        $item.Content = "$($profile.Name)    [$status]"
        $item.Padding = "10"
        $item.Margin = "0,0,0,6"

        if ($selectedName -and $profile.Name -eq $selectedName) {
            $indexToSelect = $i
        }

        $Global:ProfileList.Items.Add($item) | Out-Null
        $i++
    }

    if ($indexToSelect -ge 0) {
        $Global:ProfileList.SelectedIndex = $indexToSelect
    } elseif ($profiles.Count -eq 1) {
        $Global:ProfileList.SelectedIndex = 0
    }

    Set-Status (T "profiles_status" @($profiles.Count, $Global:ProfileRoot))
    Update-ToolsProfileCombo
}

function Start-AutoUpdateCheck {
    try {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2)
        $timer.Add_Tick({
            $this.Stop()
            Set-Status (T "checking_update")
            Install-SelfUpdate -SilentCheck
            Set-Status (T "ready")
        })
        $timer.Start()
    } catch { }
}

function Start-RefreshTimer {
    try {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(5)
        $timer.Add_Tick({
            Refresh-ProfileList
        })
        $timer.Start()
    } catch { }
}

function Save-SettingsFromUI {
    if ($Global:MainControls.ContainsKey("language_combo")) {
        $langValue = Get-ComboSelectedValue $Global:MainControls["language_combo"]
        $Global:Language = if ($langValue -eq "en") { "en" } else { "vi" }
    }

    if ($Global:MainControls.ContainsKey("theme_combo")) {
        $themeValue = Get-ComboSelectedValue $Global:MainControls["theme_combo"]
        $Global:Theme = if ($themeValue -eq "dark") { "dark" } else { "light" }
    }

    Save-Config
    Apply-Language
    Apply-Theme
    Set-Status (T "saved_settings")
}

function Build-ProfilesTab {
    $panel = New-Object System.Windows.Controls.DockPanel
    $panel.Margin = "10"

    $toolbar = New-Object System.Windows.Controls.WrapPanel
    $toolbar.Margin = "0,0,0,12"
    [System.Windows.Controls.DockPanel]::SetDock($toolbar, "Top")

    $btnAdd = New-Button "" {
        $name = [Microsoft.VisualBasic.Interaction]::InputBox((T "profile_prompt"), $Global:AppName, (T "profile_default"))
        if ($name) { New-ZaloProfile $name }
    }
    $Global:MainControls["add_profile"] = $btnAdd
    $toolbar.Children.Add($btnAdd) | Out-Null

    $btnOpen = New-Button "" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox (T "select_profile"); return }
        Start-ZaloProfile $name
    }
    $Global:MainControls["open_zalo"] = $btnOpen
    $toolbar.Children.Add($btnOpen) | Out-Null

    $btnFolder = New-Button "" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox (T "select_profile"); return }
        Open-ProfileFolder $name
    }
    $Global:MainControls["open_folder"] = $btnFolder
    $toolbar.Children.Add($btnFolder) | Out-Null

    $btnDelete = New-Button "" {
        $name = Get-SelectedProfileName
        if (-not $name) { Show-ErrorBox (T "select_profile"); return }
        Remove-ZaloProfile $name
    }
    $Global:MainControls["delete"] = $btnDelete
    $toolbar.Children.Add($btnDelete) | Out-Null

    $btnCloseAll = New-Button "" {
        Stop-AllZalo
    }
    $Global:MainControls["close_all"] = $btnCloseAll
    $toolbar.Children.Add($btnCloseAll) | Out-Null

    $Global:ProfileList = New-Object System.Windows.Controls.ListBox
    $Global:ProfileList.Margin = "0,0,0,0"
    $Global:ProfileList.FontSize = 15
    $Global:ProfileList.SelectionMode = "Single"
    $Global:ProfileList.Add_MouseDoubleClick({
        $name = Get-SelectedProfileName
        if ($name) {
            Start-ZaloProfile $name
        }
    })
    $Global:MainControls["profile_list"] = $Global:ProfileList

    $panel.Children.Add($toolbar) | Out-Null
    $panel.Children.Add($Global:ProfileList) | Out-Null

    return $panel
}

function Build-ToolsTab {
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = "16"
    $panel.Orientation = "Vertical"
    $Global:MainControls["tools_panel"] = $panel

    $title = New-Object System.Windows.Controls.TextBlock
    $title.FontSize = 20
    $title.FontWeight = "Bold"
    $title.Margin = "0,0,0,6"
    $Global:TextControls["tools_title"] = $title
    $panel.Children.Add($title) | Out-Null

    $note = New-Object System.Windows.Controls.TextBlock
    $note.TextWrapping = "Wrap"
    $note.Opacity = 0.8
    $note.Margin = "0,0,0,16"
    $Global:TextControls["muted_backup_note"] = $note
    $Global:TextControls["backup_note"] = $note
    $panel.Children.Add($note) | Out-Null

    $profileLabel = New-Label ""
    $Global:TextControls["tools_profile_label"] = $profileLabel
    $panel.Children.Add($profileLabel) | Out-Null

    $profileCombo = New-Object System.Windows.Controls.ComboBox
    $profileCombo.Width = 260
    $profileCombo.Foreground = "Black"
    $profileCombo.Background = "White"
    $profileCombo.HorizontalAlignment = "Left"
    $profileCombo.Margin = "0,0,0,16"
    $Global:MainControls["tools_profile_combo"] = $profileCombo
    $panel.Children.Add($profileCombo) | Out-Null

    $actions = New-Object System.Windows.Controls.WrapPanel
    $actions.Margin = "0,0,0,12"

    $exportBtn = New-Button "" {
        $name = Get-ToolProfileName
        if (-not $name) { Show-ErrorBox (T "select_profile"); return }
        Export-ZaloProfile $name
    } 150
    $Global:MainControls["backup_profile"] = $exportBtn
    $actions.Children.Add($exportBtn) | Out-Null

    $importBtn = New-Button "" {
        Import-ZaloProfile
    } 150
    $Global:MainControls["import_profile"] = $importBtn
    $actions.Children.Add($importBtn) | Out-Null

    $shortcutBtn = New-Button "" {
        $name = Get-ToolProfileName
        if (-not $name) { Show-ErrorBox (T "select_profile"); return }
        Create-ProfileShortcut $name
    } 150
    $Global:MainControls["create_shortcut"] = $shortcutBtn
    $actions.Children.Add($shortcutBtn) | Out-Null

    $updateBtn = New-Button "" {
        Install-SelfUpdate
    } 150
    $Global:MainControls["check_update"] = $updateBtn
    $actions.Children.Add($updateBtn) | Out-Null

    $panel.Children.Add($actions) | Out-Null

    return $panel
}
function Build-SettingsTab {
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = "16"
    $panel.Orientation = "Vertical"
    $Global:MainControls["settings_panel"] = $panel

    $title = New-Object System.Windows.Controls.TextBlock
    $title.FontSize = 20
    $title.FontWeight = "Bold"
    $title.Margin = "0,0,0,12"
    $Global:TextControls["settings_title"] = $title
    $panel.Children.Add($title) | Out-Null

    $langLabel = New-Label ""
    $Global:TextControls["language_label"] = $langLabel
    $panel.Children.Add($langLabel) | Out-Null

    $langCombo = New-Object System.Windows.Controls.ComboBox
    $langCombo.Width = 220
    $langCombo.Foreground = "Black"
    $langCombo.Background = "White"
    $langCombo.HorizontalAlignment = "Left"
    $langCombo.Margin = "0,0,0,6"
    $Global:MainControls["language_combo"] = $langCombo
    $panel.Children.Add($langCombo) | Out-Null

    $themeLabel = New-Label ""
    $Global:TextControls["theme_label"] = $themeLabel
    $panel.Children.Add($themeLabel) | Out-Null

    $themeCombo = New-Object System.Windows.Controls.ComboBox
    $themeCombo.Width = 220
    $themeCombo.Foreground = "Black"
    $themeCombo.Background = "White"
    $themeCombo.HorizontalAlignment = "Left"
    $themeCombo.Margin = "0,0,0,16"
    $Global:MainControls["theme_combo"] = $themeCombo
    $panel.Children.Add($themeCombo) | Out-Null

    $actions = New-Object System.Windows.Controls.WrapPanel
    $actions.Margin = "0,8,0,0"

    $saveBtn = New-Button "" {
        Save-SettingsFromUI
    } 140
    $Global:MainControls["save_settings"] = $saveBtn
    $actions.Children.Add($saveBtn) | Out-Null

    $panel.Children.Add($actions) | Out-Null

    return $panel
}

function Build-UI {
    $Global:Window = New-Object System.Windows.Window
    $Global:Window.Title = "$Global:AppName v$Global:Version"
    $Global:Window.Width = 820
    $Global:Window.Height = 620
    $Global:Window.MinWidth = 740
    $Global:Window.MinHeight = 540
    $Global:Window.WindowStartupLocation = "CenterScreen"

    $root = New-Object System.Windows.Controls.Grid
    $root.Margin = "18"
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "*" }))
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))

    $headerGrid = New-Object System.Windows.Controls.Grid
    $headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))
    $headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))
    [System.Windows.Controls.Grid]::SetRow($headerGrid, 0)

    $headerStack = New-Object System.Windows.Controls.StackPanel
    $headerStack.Orientation = "Vertical"
    [System.Windows.Controls.Grid]::SetColumn($headerStack, 0)

    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = $Global:AppName
    $title.FontSize = 28
    $title.FontWeight = "Bold"
    $title.Margin = "0,0,0,8"
    $Global:TextControls["title"] = $title
    $headerStack.Children.Add($title) | Out-Null

    $author = New-Object System.Windows.Controls.TextBlock
    $author.Opacity = 0.85
    $author.Margin = "0,0,0,0"
    $Global:TextControls["muted_author"] = $author
    $Global:TextControls["author"] = $author
    $headerStack.Children.Add($author) | Out-Null

    $websiteText = New-Object System.Windows.Controls.TextBlock
    $websiteText.Opacity = 0.9
    $websiteText.Margin = "0,2,0,14"
    $websiteText.Cursor = "Hand"
    $websiteText.TextDecorations = [System.Windows.TextDecorations]::Underline
    $websiteText.Add_MouseLeftButtonUp({ Open-Website })
    $Global:TextControls["link_website"] = $websiteText
    $Global:TextControls["website_line"] = $websiteText
    $headerStack.Children.Add($websiteText) | Out-Null

    $websiteButton = New-Button "" { Open-Website } 120
    $Global:MainControls["website_button"] = $websiteButton
    [System.Windows.Controls.Grid]::SetColumn($websiteButton, 1)

    $headerGrid.Children.Add($headerStack) | Out-Null
    $headerGrid.Children.Add($websiteButton) | Out-Null
    $root.Children.Add($headerGrid) | Out-Null

    $Global:TabControl = New-Object System.Windows.Controls.TabControl
    $Global:MainControls["tabs"] = $Global:TabControl
    [System.Windows.Controls.Grid]::SetRow($Global:TabControl, 1)

    $profileTab = New-Object System.Windows.Controls.TabItem
    $profileTab.Content = Build-ProfilesTab

    $toolsTab = New-Object System.Windows.Controls.TabItem
    $toolsTab.Content = Build-ToolsTab

    $settingsTab = New-Object System.Windows.Controls.TabItem
    $settingsTab.Content = Build-SettingsTab

    $Global:TabControl.Items.Add($profileTab) | Out-Null
    $Global:TabControl.Items.Add($toolsTab) | Out-Null
    $Global:TabControl.Items.Add($settingsTab) | Out-Null

    $root.Children.Add($Global:TabControl) | Out-Null

    $bottom = New-Object System.Windows.Controls.DockPanel
    [System.Windows.Controls.Grid]::SetRow($bottom, 2)

    $Global:StatusText = New-Object System.Windows.Controls.TextBlock
    $Global:StatusText.Text = ""
    $Global:StatusText.Opacity = 0.72
    $Global:StatusText.TextWrapping = "Wrap"
    $Global:TextControls["muted_status"] = $Global:StatusText
    [System.Windows.Controls.DockPanel]::SetDock($Global:StatusText, "Left")
    $bottom.Children.Add($Global:StatusText) | Out-Null

    $root.Children.Add($bottom) | Out-Null
    $Global:Window.Content = $root

    Apply-Language
    Apply-Theme
    Refresh-ProfileList
    Update-ToolsProfileCombo
    Start-RefreshTimer
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
