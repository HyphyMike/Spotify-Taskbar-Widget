# Installs or removes the logon entry that runs the Spotify watcher.
#
#   .\install-watcher.ps1            install
#   .\install-watcher.ps1 -Remove    uninstall
#   .\install-watcher.ps1 -Status    report what is currently installed
#
# Writes a shortcut into the per-user Startup folder. No admin rights, no
# registry Run key, no scheduled task — one file that can be deleted by hand.

param(
    [switch]$Remove,
    [switch]$Status
)

$ErrorActionPreference = 'Stop'

$startup = [Environment]::GetFolderPath('Startup')
$linkPath = Join-Path $startup 'Spotify Widget Watcher.lnk'
$vbs = Join-Path $PSScriptRoot 'watcher-launch.vbs'

if ($Status) {
    if (Test-Path $linkPath) {
        $shell = New-Object -ComObject WScript.Shell
        $lnk = $shell.CreateShortcut($linkPath)
        "installed: $linkPath"
        "  -> $($lnk.TargetPath) $($lnk.Arguments)"
    }
    else {
        "not installed (no $linkPath)"
    }
    # Excluding this process: its own command line mentions the script name and
    # would otherwise match.
    $running = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
        Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*spotify-widget-watcher.ps1*' }
    if ($running) { "watcher running, pid $($running.ProcessId -join ', ')" } else { "watcher not running" }
    return
}

if ($Remove) {
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
        "removed $linkPath"
    }
    else {
        "nothing to remove"
    }
    # Excluding this process: its own command line mentions the script name and
    # would otherwise match.
    $running = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
        Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*spotify-widget-watcher.ps1*' }
    foreach ($p in $running) {
        Stop-Process -Id $p.ProcessId -Force
        "stopped watcher pid $($p.ProcessId)"
    }
    return
}

if (-not (Test-Path $vbs)) { throw "missing $vbs" }

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($linkPath)
$lnk.TargetPath = 'wscript.exe'
$lnk.Arguments = """$vbs"""
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.Description = 'Opens the Spotify taskbar widget while Spotify is running'
$lnk.Save()

"installed $linkPath"
"  -> wscript.exe ""$vbs"""
