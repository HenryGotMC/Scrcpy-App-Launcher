$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbsPath = Join-Path $scriptDir "scrcpy-menu.vbs"

Write-Host "Checking dependencies..."
$missing = @()
foreach ($cmd in @("scrcpy", "adb")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        $missing += $cmd
    }
}
if ($missing.Count -gt 0) {
    Write-Host "Missing required commands: $($missing -join ', ')"
    Write-Host "Download scrcpy (it bundles adb) from https://github.com/Genymobile/scrcpy/releases,"
    Write-Host "extract it, and add that folder to your PATH. Then re-run this script."
    exit 1
}

$startMenu = [Environment]::GetFolderPath("Programs")
$shortcutPath = Join-Path $startMenu "Scrcpy Manga-Shows.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WorkingDirectory = $scriptDir
$shortcut.Description = "Launch scrcpy for manga reading or show watching"
$shortcut.Save()

Write-Host "Installed. Search for 'Scrcpy Manga-Shows' in the Start Menu."
Write-Host "Edit profiles.conf (in the repo root) to add your own resolutions and app package names."
