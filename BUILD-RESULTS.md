# Local build results

Built on 2026-09-10 from the local `local-hardening` branch, which carries the
hardening documented in `SECURITY-LOCAL.md` on top of upstream commit
`7520b2a8d4662ff94675d341d69943b50b078614` (`v0.3.5`). This local build is
version `0.3.9`. The Spotify client ID is supplied per installation at runtime and
is not part of the build — see **Configuring the client ID** below.

New in `0.3.9`:

- A native close request (Alt+F4, or an external `WM_CLOSE`) hides the bar to
  the tray instead of exiting — restored from upstream after a prior hardening
  pass had removed it. The visible X drawn inside the bar is still a real quit,
  unchanged. See `SECURITY-LOCAL.md` for the reasoning.
- The Spotify watcher now ends the widget with `Stop-Process` instead of
  `CloseMainWindow`, since the latter is now indistinguishable from a user's own
  close request and would just hide it. Also gained a single-instance guard
  (found the hard way — see `SECURITY-LOCAL.md`).

New in `0.3.8`:

- The bar sits inside the taskbar strip and re-claims the top of the z-order once
  a second, because the taskbar is always-on-top too and buried the bar whenever
  it was activated.
- No taskbar button of its own (`skipTaskbar`); the tray icon and its
  Show Player / Quit menu are the way back to a hidden window.
- Rounded with no corner artifacts. The grey wedges at the corners were the OS
  window shadow showing through the transparent page, removed with
  `"shadow": false`; `backdrop-filter` was removed because an OS-transparent
  window has no backdrop to sample and it rendered as a dark slab.
- Bitmori purple palette at 50% opacity, replacing the Spotify green, the
  per-track accent sampled from album art, and the hardcoded inline background
  in `renderer.js`. All three used to override the theme.
- Optional Spotify watcher in `tools/` — see `SECURITY-LOCAL.md`.
- The Spotify client ID is no longer compiled in; it's read from
  `SPOTIFY_CLIENT_ID` or `config.json` at runtime, so it's safe to publish this
  source publicly. See **Configuring the client ID** below.

## Ready-to-run files

| File | SHA-256 |
| --- | --- |
| `dist/Spotify Taskbar Widget Portable.exe` | `86B65436C669E855ADBEE493F9F88718A535214C63B373CA41EA8D8ED8E238CA` |
| `dist/Spotify Taskbar Widget 0.3.9 Setup.exe` | `4466C4868690B815AA43E3657F77676AD7CFC845AAB90F0508C5D7E808181BEE` |
| `dist/Spotify Taskbar Widget 0.3.9.msi` | `07B1D6B9DD822C0061B8F3030BA189940781AC423073DCBDD0FA5FEC788EFE7B` |

The `0.3.5` and `0.3.7` artifacts from earlier builds are still in `dist/`
alongside these; the portable executable is overwritten in place each build.

The copy installed at
`%LOCALAPPDATA%\Spotify Taskbar Widget\spotify-taskbar-widget.exe` is byte-identical
to the portable executable above. The `0.3.7` binary it replaced was kept beside
it as `spotify-taskbar-widget.exe.0.3.7.bak`.

## Verification

- Rust unit tests: 22 passed, 0 failed (15 original, 3 covering the taskbar seat
  geometry, 4 covering the runtime client-ID lookup).
- npm audit: 0 known vulnerabilities.
- JavaScript syntax checks: passed.
- Placement: the bar sits at y=1040 on a 1920x1080 primary display whose taskbar
  occupies 1040-1080 — inside the strip, not above it.
- Z-order: the taskbar was forced to the top of the topmost band, the way
  clicking Start does. The bar was covered, and had reclaimed the top 1.6s later.
- Screen space: the desktop work area stayed at 1040px. An earlier attempt that
  registered a Windows AppBar reserved 40px and was abandoned — see
  `SECURITY-LOCAL.md`.
- No taskbar button: the taskbar button row was captured with the widget running
  and again with it closed. The two images are identical. (The window ex-styles
  still report `WS_EX_APPWINDOW`, because Tauri removes the button through
  `ITaskbarList::DeleteTab` rather than by setting `WS_EX_TOOLWINDOW` — the style
  bits are not a valid check here.)
- Colour: against a taskbar reading `rgb(220,224,235)`, the bar fill measures
  `rgb(133,121,146)` — the 50% purple blend — and the pixel just inside a rounded
  corner measures `rgb(220,227,235)`, identical to bare taskbar.
- Close-to-tray: sent the widget's own process a native close request (the
  same `WM_CLOSE` Alt+F4 or an external `CloseMainWindow()` sends). Sampled
  visibility every 300ms for 2.7 seconds afterward — immediately false and
  stable throughout, while the process stayed alive. Confirmed it survives the
  taskbar-pinning background thread specifically (which touches the window
  every second): no flicker back to visible across three full pin cycles.
- Watcher, open path: with Spotify running, the widget was closed and the
  watcher started; the widget was back within 7 seconds.
- Watcher, close path (re-verified against the `0.3.9` Stop-Process mechanism,
  since the earlier `0.3.8` result tested the older CloseMainWindow path):
  with both running, Spotify was closed gracefully; the widget's *process*
  ended, not just its window — confirmed via `Get-Process`, not just a
  visibility check, since the whole point of this path is freeing the memory.
  Spotify was then relaunched; the widget reopened on its own. No manual step
  either direction.
- Watcher robustness: the mutex and abandoned-mutex fix were verified directly
  — launched a watcher, force-killed it (abandoning the mutex on purpose),
  launched a second, and confirmed it stayed running rather than crashing
  silently on the unhandled exception the first version of this fix would have
  produced.
- Microsoft Defender custom scan: no threats found in the portable executable,
  NSIS installer, or MSI.
- The files are not Authenticode-signed. Windows SmartScreen may warn because
  this is a personal local build without a paid code-signing certificate.
- Tray icon: lands in the hidden overflow rather than the visible tray on first
  run (Windows' default for a new icon) — confirmed directly, since the tray
  toolbar window classes needed to check this programmatically do not resolve
  on this Windows build. Drag it out from under the `^` chevron to pin it.

## Configuring the client ID

The widget needs the client ID of a Spotify application you create at
<https://developer.spotify.com/dashboard>, with
`http://127.0.0.1:4381/callback` added as a redirect URI. Supply it either way:

- set the `SPOTIFY_CLIENT_ID` environment variable, or
- copy `config.example.json` to `config.json` — beside the executable, or in
  `%APPDATA%\com.madal.spotify-taskbar-widget\` — and put the ID in it.

`config.json` is git-ignored. Without one, **Connect Spotify** reports which
locations were searched instead of failing against Spotify's generic
`INVALID_CLIENT` page.

## Running it

Use `dist/Spotify Taskbar Widget Portable.exe` to run without installation, or
use either installer. Click **Connect Spotify** and approve the requested
playback/library permissions in Spotify. Tokens are saved in Windows Credential
Manager under `com.madal.spotify-taskbar-widget`, and are cleared automatically
if a token refresh ever fails — a re-connect is expected after that.

A Spotify Premium account is required by Spotify's Web Playback SDK.
