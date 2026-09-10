# Local security notes

This build is compiled locally from the public source at tag `v0.3.5`, with
additional hardening:

- Spotify OAuth uses the user-supplied client ID; no client secret is embedded.
- Spotify OAuth uses PKCE and validates a per-login `state` value.
- Tokens are stored in the operating system credential vault, not plaintext.
- The webview may load scripts only from the app itself and Spotify's official
  Playback SDK host.
- Network connections from the webview are restricted to Spotify domains.
- The backend only sends API requests to `https://api.spotify.com/v1/`.
- Unneeded profile and email scopes have been removed.
- No updater, startup task, telemetry, shell execution, or arbitrary file access
  is included.
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
