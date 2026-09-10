# Local security notes

This build is compiled locally from the public source at tag `v0.3.5`, with
additional hardening:

- Spotify OAuth uses a per-installation client ID read at runtime from
  `SPOTIFY_CLIENT_ID` or `config.json`; nothing is compiled in and no client
  secret exists to embed. A PKCE client ID is not a cryptographic secret — it
  travels in the authorization URL in plain sight — but it identifies one
  Spotify app registration, so it stays out of the repository rather than
  inviting strangers to spend someone else's API quota.
- Spotify OAuth uses PKCE and validates a per-login `state` value.
- Tokens are stored in the operating system credential vault, not plaintext.
- The webview may load scripts only from the app itself and Spotify's official
  Playback SDK host.
- Network connections from the webview are restricted to Spotify domains.
- The backend only sends API requests to `https://api.spotify.com/v1/`.
- Unneeded profile and email scopes have been removed.
- No updater, telemetry, shell execution, or arbitrary file access is included,
  and the application never registers itself to start with Windows. (The
  optional watcher in `tools/` does install a logon entry — see below. It is a
  separate script, installed by hand, and the widget knows nothing about it.)
- The visible X drawn inside the bar is a real quit — clicking it exits the
  process, same as upstream. A native close request instead (Alt+F4, or an
  external `WM_CLOSE`; there's no titlebar for the OS to draw one on) hides to
  the tray without exiting, as of `0.3.9` — restoring what upstream does, which
  an earlier hardening pass had turned into an unconditional exit. Reversed at
  the user's request: keeping a companion widget resident and instantly
  reachable from the tray isn't a meaningful security boundary for a purely
  local app with no elevated privileges, autostart, or telemetry, and the prior
  behavior contradicted this very README, which has always advertised
  "Background Operation: Runs in the system tray."

The official Spotify Playback SDK remains remote code supplied by Spotify. It is
required for this widget to act as its own Spotify Connect playback device.

## Shell interaction this build adds

Since `0.3.8` the widget sits inside the taskbar strip and re-claims the top of
the topmost window band once per second, because the taskbar is topmost too and
buries the bar whenever it is activated.

- It reads the taskbar's screen rectangle (`FindWindowW` on `Shell_TrayWnd`) to
  work out where to sit, and raises its own window with `SWP_NOACTIVATE` so it
  never steals focus.
- No screen space is reserved and no global shell state is created, so nothing
  has to be cleaned up if the process dies: killing it leaves the desktop exactly
  as it was.
- An AppBar registration (`SHAppBarMessage`) was tried first and removed. It
  works, but the shell refuses to let a docked bar overlap the taskbar, so it
  could only ever sit above the taskbar rather than in it.

## Optional Spotify watcher (`tools/`)

`tools/install-watcher.ps1` adds one shortcut to the per-user Startup folder,
pointing at `watcher-launch.vbs`, which runs `spotify-widget-watcher.ps1` hidden.
That script polls the process list every 3 seconds and opens the widget while
Spotify is running, closing it again when Spotify quits.

- No admin rights, no registry `Run` key, no elevation. The default install is
  a single `.lnk` that can be deleted by hand, or removed with
  `install-watcher.ps1 -Remove`. `install-watcher.ps1 -ScheduledTask` registers
  a Scheduled Task instead, with restart-on-failure — see below.
- Something on this machine kills the watcher process periodically, confirmed
  during this feature's own testing: it happened twice, both times with no
  trace in its own crash log (see below) or in Defender's detection history,
  meaning it isn't an unhandled exception or a flagged behavior — something
  external is ending the process outright. Root cause not identified. A
  specific lead (a DeepSeek/Charm-based review-watcher script also present on
  this machine, `Watch-DeepSeek.ps1`) was checked directly and ruled out: it
  never touches the process list at all, and this watcher runs with
  `-NoProfile` regardless, so it wouldn't load that tooling's profile setup
  even if it did.
- `spotify-widget-watcher.ps1` now logs any unhandled exception to
  `%APPDATA%\com.madal.spotify-taskbar-widget\watcher-crash.log` (overwritten
  each time, so it can't grow unbounded) before exiting. Added specifically
  because `wscript.exe`'s whole purpose is running hidden with zero console
  output, which also means a crash leaves zero trace by default —
  `install-watcher.ps1 -Status` surfaces whether this file exists.
- Polling was chosen over a WMI `Win32_ProcessStartTrace` subscription
  deliberately: that route needs elevation and leaves a permanent WMI event
  consumer behind, which is a far larger and more persistent footprint.
- The script reads process names only. It starts one fixed executable path and
  ends the widget by PID; it takes no input from anything it observes.
- As of `0.3.9`, ends the widget with `Stop-Process` rather than
  `CloseMainWindow`. The widget's own close request now means "hide", not
  "quit" (see above) — the two are indistinguishable to an outside process,
  since both arrive as the same `WM_CLOSE`, so `CloseMainWindow` would just hide
  it here instead of freeing the memory. Window position is already persisted
  continuously on every move/resize, not only at close time, so nothing is lost
  by ending the process directly.
- Guarded against running twice with a named mutex (`WaitOne(0)`), since the
  Startup shortcut fires on every logon and a second instance's local
  `$widgetWasUp`/`$suppressed` state has no way to stay in sync with the
  first's — found by running one during this session's own testing and having
  two overlapping instances race each other's `Start-Process`/`Stop-Process`
  calls. The mutex needed one more fix on top: .NET marks a mutex "abandoned"
  when its holder dies without releasing it (exactly what `Stop-Process -Force`
  on a running watcher does), and `WaitOne` throws
  `AbandonedMutexException` in that case rather than just returning `true` —
  left unhandled, that exception kills the script before it ever reaches the
  polling loop, silently, on every future launch. Caught explicitly and treated
  as ordinary acquisition, which is what .NET's own documentation says it is.

### The Scheduled Task alternative

`install-watcher.ps1 -ScheduledTask` registers the watcher as a Scheduled Task
(`MultipleInstances IgnoreNew`, `RestartCount 999` a minute apart) instead of a
Startup shortcut, so whatever is killing the process gets overridden
automatically rather than leaving the widget stuck without its companion until
the next logon. This could not be set up from this development session — even
the most minimal possible task registration failed with "Access is denied"
from this sandboxed shell, a hard permission wall rather than a parameter
issue. Run `install-watcher.ps1 -ScheduledTask` yourself from an ordinary
terminal if you want that resilience; it does not need administrator rights,
only rights this particular session's shell doesn't have.
