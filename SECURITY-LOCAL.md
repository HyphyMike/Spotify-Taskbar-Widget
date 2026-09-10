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
