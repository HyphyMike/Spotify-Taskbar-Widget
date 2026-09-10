# Local build results

Built on 2026-08-24 from upstream commit
`7520b2a8d4662ff94675d341d69943b50b078614` (`v0.3.5`) after applying the
hardening documented in `SECURITY-LOCAL.md`. This local build is version `0.3.7`
and Spotify OAuth is configured with the user-supplied Client ID
`CLIENT_ID_SUPPLIED_AT_RUNTIME`.

## Ready-to-run files

| File | SHA-256 |
| --- | --- |
| `dist/Spotify Taskbar Widget Portable.exe` | `46629EDBA505EAAB36C7A9AB2DA1534E6443B63BD6181A8C0A2D4FEA19CEE3D8` |
| `dist/Spotify Taskbar Widget 0.3.7 Setup.exe` | `4048DD3EFD61BCB4B8487E52537ED3531B270CC59359FC90DAEABC774EE38B80` |
| `dist/Spotify Taskbar Widget 0.3.7.msi` | `A64ABBA627E7A5AAB214BD42BF2A9243613B542AC14E40B0D0F512C80557C74D` |

## Verification

- Rust unit tests: 15 passed, 0 failed.
- npm audit: 0 known vulnerabilities.
- JavaScript syntax checks: passed.
- Tauri and capability JSON parsing: passed.
- Launch test: a visible window appeared.
- Close test: a standard Windows close event terminated the process instead of
  leaving it hidden in the tray.
- Microsoft Defender custom scan: no threats found in the portable executable,
  NSIS installer, or MSI.
- The files are not Authenticode-signed. Windows SmartScreen may warn because
  this is a personal local build without a paid code-signing certificate.

## Running it

Use `dist/Spotify Taskbar Widget Portable.exe` to run without installation, or
use either installer. Click **Connect Spotify** and approve the requested
playback/library permissions in Spotify. Tokens are saved in Windows Credential
Manager under `com.madal.spotify-taskbar-widget`.

A Spotify Premium account is required by Spotify's Web Playback SDK.
