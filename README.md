# ZaloMulti

Author: Nguyễn Lê Khánh Hòa  
Website: https://koha.io.vn

## Features

- Run multiple Zalo Desktop profiles.
- No extra Windows user required.
- Language: Tiếng Việt / English.
- Theme: Sáng / Tối.
- Website link in header.
- Tools tab: Export profile, Import profile, Create shortcut, Check update.
- Single EXE distribution.
- EXE auto-update from GitHub.

## User distribution

Send only:

```text
ZaloMulti.exe
```

Users must install Zalo PC first.

## Developer files

```text
ZaloMulti.ps1
ZaloMulti.bat
Build-Exe.ps1
Build-Exe.bat
version.txt
logo.png
logo.ico          optional
release/
  ZaloMulti.exe
```

## Build EXE

Double-click:

```text
Build-Exe.bat
```

Output:

```text
ZaloMulti.exe
```

## Auto update

The exe checks:

```text
https://raw.githubusercontent.com/koha2002/MultiZalo/main/version.txt
```

If newer, it downloads:

```text
https://raw.githubusercontent.com/koha2002/MultiZalo/main/release/ZaloMulti.exe
```

So GitHub must contain:

```text
version.txt
release/ZaloMulti.exe
```

## Release new version

1. Edit `ZaloMulti.ps1`.
2. Increase version:
   ```powershell
   $Global:Version = "1.2.5"
   ```
3. Change `version.txt`:
   ```text
   1.2.5
   ```
4. Run `Build-Exe.bat`.
5. Upload the new exe to:
   ```text
   release/ZaloMulti.exe
   ```
6. Push to GitHub.
