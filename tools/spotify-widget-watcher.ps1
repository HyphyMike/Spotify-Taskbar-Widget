# Opens the taskbar widget when Spotify starts, and closes it when Spotify quits.
#
# Runs as a logon task. Polling rather than a WMI process-start subscription:
# Win32_ProcessStartTrace needs elevation, and a permanent WMI consumer is a far
# heavier footprint than checking a process list every few seconds.

$WidgetExe = Join-Path $env:LOCALAPPDATA 'Spotify Taskbar Widget\spotify-taskbar-widget.exe'

# Refuse to run twice. The Startup shortcut fires on every logon, and each
# instance's $widgetWasUp/$suppressed state below is local to that process, so
# two overlapping instances can independently reach different conclusions
# about the same widget and end up racing each other's Start-Process /
# Stop-Process calls. A named mutex costs nothing per poll and makes a second
# launch (another logon while one is already running, or a manual re-run) a
# clean no-op instead of a silent duplicate.
$mutex = New-Object System.Threading.Mutex($false, 'Local\SpotifyTaskbarWidgetWatcher')
try {
    if (-not $mutex.WaitOne(0)) {
        exit
    }
}
catch [System.Threading.AbandonedMutexException] {
    # A previous holder died (crashed, or was force-killed) without releasing
    # the mutex. .NET still hands this thread ownership when that happens --
    # WaitOne's return value is moot, since it throws instead of returning --
    # so this is the normal "I got it" path, not a failure: fall through to
    # the polling loop rather than treating the exception as "someone else
    # has it" and exiting.
}

# Close the widget when Spotify quits. Set to $false to leave the bar up.
$CloseWithSpotify = $true

$PollSeconds = 3

# Tracks whether the widget was up earlier in this Spotify session. If it was and
# it is gone now, the user closed it deliberately, so it must not be relaunched
# until Spotify itself restarts — otherwise clicking the widget's own X would
# just bring it back a few seconds later.
$widgetWasUp = $false
$suppressed = $false

while ($true) {
    $spotifyUp = $null -ne (Get-Process Spotify -ErrorAction SilentlyContinue)
    $widget = Get-Process spotify-taskbar-widget -ErrorAction SilentlyContinue
    $widgetUp = $null -ne $widget

    if ($spotifyUp) {
        if ($widgetUp) {
            $widgetWasUp = $true
        }
        elseif ($widgetWasUp) {
            # It was up and now is not: a deliberate close. Stand down.
            $suppressed = $true
            $widgetWasUp = $false
        }
        elseif (-not $suppressed) {
            if (Test-Path $WidgetExe) {
                Start-Process $WidgetExe
                $widgetWasUp = $true
            }
        }
    }
    else {
        # Spotify is gone: forget the session so the next launch starts clean.
        $suppressed = $false
        $widgetWasUp = $false

        if ($widgetUp -and $CloseWithSpotify) {
            # Stop-Process, not CloseMainWindow: the widget now hides to the tray
            # instead of exiting on a normal close request (Alt+F4, or exactly the
            # WM_CLOSE that CloseMainWindow used to send), so CloseMainWindow would
            # just hide it here rather than free the memory. Window position is
            # already persisted continuously on every move/resize, not only at
            # close time, so nothing is lost by ending the process directly.
            foreach ($p in $widget) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        }
    }

    Start-Sleep -Seconds $PollSeconds
}
