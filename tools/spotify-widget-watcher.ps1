# Opens the taskbar widget when Spotify starts, and closes it when Spotify quits.
#
# Runs as a logon task. Polling rather than a WMI process-start subscription:
# Win32_ProcessStartTrace needs elevation, and a permanent WMI consumer is a far
# heavier footprint than checking a process list every few seconds.

$WidgetExe = Join-Path $env:LOCALAPPDATA 'Spotify Taskbar Widget\spotify-taskbar-widget.exe'

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
            # CloseMainWindow, not Kill: the widget saves its window position on
            # a normal close.
            foreach ($p in $widget) { [void]$p.CloseMainWindow() }
        }
    }

    Start-Sleep -Seconds $PollSeconds
}
