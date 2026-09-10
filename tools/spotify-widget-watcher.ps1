# Opens the taskbar widget when the official Spotify desktop app starts.
#
# Does NOT close the widget when Spotify quits, or ever tie the widget's
# lifetime to Spotify's. That was this script's original design and it was
# backwards: the widget is a standalone Spotify Connect device in its own
# right (Web Playback SDK, see renderer.js) built specifically to replace the
# ~500MB-1GB+ official desktop app, not to accompany it. A "close when Spotify
# quits" rule fights the app's entire reason to exist -- it would silently
# kill the widget's own playback within one poll interval of closing the very
# app the widget is meant to make unnecessary.
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

$PollSeconds = 3

# Tracks whether the widget was up earlier in this Spotify session. If it was and
# it is gone now, the user closed it deliberately, so it must not be relaunched
# until Spotify itself restarts — otherwise clicking the widget's own X would
# just bring it back a few seconds later.
$widgetWasUp = $false
$suppressed = $false

# wscript.exe launches this hidden specifically so nothing ever flashes on
# screen, which also means an unhandled exception here fails with zero trace —
# the process just silently stops existing. Found this out directly, chasing
# exactly that during this feature's own testing. A crash log costs nothing
# while things are working, and is the only way to tell "it crashed" from "it
# was never running" the next time something goes wrong. Overwritten on each
# failure rather than appended, so it can't grow unbounded — only the most
# recent crash matters.
$crashLog = Join-Path $env:APPDATA 'com.madal.spotify-taskbar-widget\watcher-crash.log'

try {
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
            # Spotify is gone. The widget is left alone -- it doesn't need
            # Spotify's desktop client to keep playing (see the header comment)
            # -- and only the "was it opened because Spotify launched"
            # bookkeeping resets, so a future Spotify launch starts fresh rather
            # than carrying forward suppression state from a previous session.
            $suppressed = $false
            $widgetWasUp = $false
        }

        Start-Sleep -Seconds $PollSeconds
    }
}
catch {
    $dir = Split-Path $crashLog
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    "$(Get-Date -Format o)  $($_ | Out-String)" | Set-Content -Path $crashLog -Encoding utf8
}
