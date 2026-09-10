# Local build results

Built on 2026-09-09 from the local `local-hardening` branch, which carries the
hardening documented in `SECURITY-LOCAL.md` on top of upstream commit
`7520b2a8d4662ff94675d341d69943b50b078614` (`v0.3.5`). This local build is
version `0.3.8` and Spotify OAuth is configured with the user-supplied Client ID
`CLIENT_ID_SUPPLIED_AT_RUNTIME`.

New in `0.3.8`: the bar sits inside the taskbar strip and re-claims the top of
the z-order once a second, because the taskbar is always-on-top too and buried
the bar whenever it was activated. See `SECURITY-LOCAL.md` for what that touches.

## Ready-to-run files

| File | SHA-256 |
| --- | --- |
| `dist/Spotify Taskbar Widget Portable.exe` | `10326156F96174C49B8561287D4DD69CF61869A000E56CA8A85233395B3C1CF4` |
| `dist/Spotify Taskbar Widget 0.3.8 Setup.exe` | `237D8AFC0CA94F8E17F57945D0B78D395C2E152A9ACFAF29C6B22ED450B68949` |
| `dist/Spotify Taskbar Widget 0.3.8.msi` | `BAE25284084D35096C44838C57E3C727E28A13FA8ED8A1701080D5249DD586A7` |

The `0.3.7` artifacts from the 2026-08-24 build are still in `dist/` alongside
these; the portable executable was overwritten in place.

## Verification

- Rust unit tests: 18 passed, 0 failed (15 pre-existing, 3 covering the taskbar
  seat geometry).
- npm audit: 0 known vulnerabilities.
- JavaScript syntax checks: passed.
- Placement test: the bar sits at y=1040 on a 1920x1080 primary display whose
  taskbar occupies 1040-1080 — inside the strip, not above it.
- Z-order test: the taskbar was forced to the top of the topmost band, the way
  clicking Start does it. The bar was covered, and had reclaimed the top 1.6s
  later.
- Screen space: the desktop work area stayed at 1040px. An earlier attempt that
  registered a Windows AppBar reserved 40px and was abandoned — see
  `SECURITY-LOCAL.md`.
- Microsoft Defender custom scan: no threats found in the portable executable,
  NSIS installer, or MSI.
- The files are not Authenticode-signed. Windows SmartScreen may warn because
  this is a personal local build without a paid code-signing certificate.

## Running it

Use `dist/Spotify Taskbar Widget Portable.exe` to run without installation, or
use either installer. Click **Connect Spotify** and approve the requested
playback/library permissions in Spotify. Tokens are saved in Windows Credential
Manager under `com.madal.spotify-taskbar-widget`, and are cleared automatically
if a token refresh ever fails — a re-connect is expected after that.

A Spotify Premium account is required by Spotify's Web Playback SDK.
