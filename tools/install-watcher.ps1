# Installs or removes the logon entry that runs the Spotify watcher.
#
#   .\install-watcher.ps1                 install (Startup-folder shortcut)
#   .\install-watcher.ps1 -Remove         uninstall whichever form is present
#   .\install-watcher.ps1 -Status         report what is currently installed
#   .\install-watcher.ps1 -ScheduledTask  install as a Scheduled Task instead
#
# Default: a shortcut in the per-user Startup folder. No admin rights, no
# registry Run key, no scheduled task — one file that can be deleted by hand.
# Its downside is exactly that simplicity: if the watcher process ever dies
# between logons (killed by something else on the machine — this has actually
# happened; see SECURITY-LOCAL.md), nothing brings it back until the next one.
#
# -ScheduledTask trades that for Task Scheduler's own restart-on-failure
# setting, which relaunches the process automatically no matter what kills it.
# Registering a task needs rights this session's own sandboxed shell does not
# have — confirmed directly, "Access is denied" even on a minimal task with no
# customization — so that path exists for you to run yourself from an ordinary
# terminal, not something this session can set up unattended.

param(
    [switch]$Remove,
    [switch]$Status,
    [switch]$ScheduledTask
)

$ErrorActionPreference = 'Stop'

$TaskName = 'Spotify Taskbar Widget Watcher'
$startup = [Environment]::GetFolderPath('Startup')
$linkPath = Join-Path $startup 'Spotify Widget Watcher.lnk'
$vbs = Join-Path $PSScriptRoot 'watcher-launch.vbs'
$script = Join-Path $PSScriptRoot 'spotify-widget-watcher.ps1'

function Get-RunningWatcherProcess {
    # Excluding this process: its own command line mentions the script name
    # and would otherwise match.
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
        Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*spotify-widget-watcher.ps1*' }
}

if ($Status) {
    if (Test-Path $linkPath) {
        $shell = New-Object -ComObject WScript.Shell
        $lnk = $shell.CreateShortcut($linkPath)
        "installed (Startup shortcut): $linkPath"
        "  -> $($lnk.TargetPath) $($lnk.Arguments)"
    }
    else {
        "no Startup shortcut"
    }

    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        $info = $task | Get-ScheduledTaskInfo
        "installed (Scheduled Task): '$TaskName', state=$($task.State), last run=$($info.LastRunTime)"
    }
    else {
        "no scheduled task"
    }

    $running = Get-RunningWatcherProcess
    if ($running) { "watcher process running, pid $($running.ProcessId -join ', ')" } else { "watcher process not running" }

    $crashLog = Join-Path $env:APPDATA 'com.madal.spotify-taskbar-widget\watcher-crash.log'
    if (Test-Path $crashLog) { "CRASH LOG PRESENT ($crashLog) -- the watcher hit an unhandled exception; read it" }
    return
}

if ($Remove) {
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
        "removed $linkPath"
    }
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        "removed scheduled task '$TaskName'"
    }
    if (-not (Test-Path $linkPath) -and -not $task) { "nothing to remove" }

    foreach ($p in (Get-RunningWatcherProcess)) {
        Stop-Process -Id $p.ProcessId -Force
        "stopped watcher pid $($p.ProcessId)"
    }
    return
}

if ($ScheduledTask) {
    if (-not (Test-Path $script)) { throw "missing $script" }

    # -WindowStyle Hidden does the console-flash-avoidance job the VBS wrapper
    # does for the Startup-shortcut path; a Scheduled Task action isn't tied to
    # an interactive console the same way a Startup-folder launch is, so the
    # VBS trick isn't needed here.
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet `
        -MultipleInstances IgnoreNew `
        -RestartCount 999 `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -DontStopOnIdleEnd `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries
    $principal = New-ScheduledTaskPrincipal -UserId "$env:COMPUTERNAME\$env:USERNAME" -LogonType Interactive -RunLevel Limited

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
        -Settings $settings -Principal $principal -Force | Out-Null

    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
        "removed the Startup shortcut so the watcher isn't launched twice"
    }

    "installed scheduled task '$TaskName'"
    "  restart-on-failure: up to 999 times, 1 minute apart"
    "  run now, without logging off/on: Start-ScheduledTask -TaskName '$TaskName'"
    return
}

if (-not (Test-Path $vbs)) { throw "missing $vbs" }

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    "removed the scheduled task so the watcher isn't launched twice"
}

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($linkPath)
$lnk.TargetPath = 'wscript.exe'
$lnk.Arguments = """$vbs"""
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.Description = 'Opens the Spotify taskbar widget while Spotify is running'
$lnk.Save()

"installed $linkPath"
"  -> wscript.exe ""$vbs"""
