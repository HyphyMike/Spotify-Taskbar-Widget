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
- Closing the player window terminates the app instead of leaving a hidden
  background process.

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

- No admin rights, no registry `Run` key, no scheduled task, no elevation. The
  install is a single `.lnk` that can be deleted by hand, or removed with
  `install-watcher.ps1 -Remove`.
- Polling was chosen over a WMI `Win32_ProcessStartTrace` subscription
  deliberately: that route needs elevation and leaves a permanent WMI event
  consumer behind, which is a far larger and more persistent footprint.
- The script reads process names only. It starts one fixed executable path and
  closes windows by handle; it takes no input from anything it observes.
