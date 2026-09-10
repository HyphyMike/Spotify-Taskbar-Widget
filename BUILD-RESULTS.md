# Local build results

Built on 2026-09-09 from the local `local-hardening` branch, which carries the
hardening documented in `SECURITY-LOCAL.md` on top of upstream commit
`7520b2a8d4662ff94675d341d69943b50b078614` (`v0.3.5`). This local build is
version `0.3.8` and Spotify OAuth is configured with the user-supplied Client ID
`CLIENT_ID_SUPPLIED_AT_RUNTIME`.

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

## Ready-to-run files

| File | SHA-256 |
| --- | --- |
| `dist/Spotify Taskbar Widget Portable.exe` | `0C76C0D013E7D3BB6E260115BA525F886FE861ACA701437225D2334BAFC3DC48` |
| `dist/Spotify Taskbar Widget 0.3.8 Setup.exe` | `37BB3E06110B850E2BA093AFA1BEFBADF1FE0311B75FA924A0EE80865CADCC7D` |
| `dist/Spotify Taskbar Widget 0.3.8.msi` | `9927D3D19EB399BCD9EDD439CB7D686CC563A3E161B25EA5391BA20E69E83600` |

The `0.3.5` and `0.3.7` artifacts from earlier builds are still in `dist/`
alongside these; the portable executable is overwritten in place each build.

The copy installed at
`%LOCALAPPDATA%\Spotify Taskbar Widget\spotify-taskbar-widget.exe` is byte-identical
to the portable executable above. The `0.3.7` binary it replaced was kept beside
it as `spotify-taskbar-widget.exe.0.3.7.bak`.

## Verification

- Rust unit tests: 18 passed, 0 failed (15 pre-existing, 3 covering the taskbar
  seat geometry).
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
- Watcher: with Spotify running, the widget was closed and the watcher started;
  the widget was back within 7 seconds.
- Microsoft Defender custom scan: no threats found in the portable executable,
  NSIS installer, or MSI.
- The files are not Authenticode-signed. Windows SmartScreen may warn because
  this is a personal local build without a paid code-signing certificate.

Not verified: the watcher's close-the-widget-when-Spotify-quits path, which would
have meant killing Spotify mid-playback; and whether the tray icon lands in the
visible tray or the hidden overflow, since the tray toolbar window classes do not
resolve on this Windows build.

## Running it

Use `dist/Spotify Taskbar Widget Portable.exe` to run without installation, or
use either installer. Click **Connect Spotify** and approve the requested
playback/library permissions in Spotify. Tokens are saved in Windows Credential
Manager under `com.madal.spotify-taskbar-widget`, and are cleared automatically
if a token refresh ever fails — a re-connect is expected after that.

A Spotify Premium account is required by Spotify's Web Playback SDK.
