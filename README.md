# Spotify Taskbar Widget

<p align="center">
  <img src="./assets/header.png" alt="Spotify Taskbar Widget Banner" width="600">
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/HyphyMike/Spotify-Taskbar-Widget?style=for-the-badge&color=1DB954" alt="Release">
  <img src="https://img.shields.io/github/actions/workflow/status/HyphyMike/Spotify-Taskbar-Widget/release.yml?style=for-the-badge" alt="Build Status">
  <img src="https://img.shields.io/github/license/HyphyMike/Spotify-Taskbar-Widget?style=for-the-badge" alt="License">
</p>

---

> **This is a modified copy**, based on [MadalinaCarcea221989/Spotify-Taskbar-Widget](https://github.com/MadalinaCarcea221989/Spotify-Taskbar-Widget) at `v0.3.5`. Changes here:
>
> - Security hardening — OAuth `state` validation, tokens in the OS credential vault, tightened CSP and scopes ([SECURITY-LOCAL.md](SECURITY-LOCAL.md))
> - The bar sits **inside** the Windows 10 taskbar and holds its z-order against it, rather than floating above
> - Purple theme, square-free rounded corners, 50% translucency
> - Optional watcher that opens the widget with Spotify ([tools/](tools/))
>
> **You must supply your own Spotify client ID** — see [Configuring the client ID](BUILD-RESULTS.md#configuring-the-client-id). None is bundled.

A premium, ultra-slim (40px) Spotify mini-player designed for native desktop integration. Compatible with Windows 11, macOS, and Linux, this widget integrates into your Taskbar or Menu Bar for seamless playback control.

## Performance Comparison

| Feature | Official Spotify App | Spotify Taskbar Widget |
| :--- | :---: | :---: |
| RAM Usage | ~500MB - 1GB+ | **~50MB - 80MB** |
| Footprint | Full Window | **Ultra-Slim 40px** |
| Tech Stack | Electron | **Tauri + Rust** |
| System Impact | High | **Minimal** |
| Integration | Standard Window | **Native Desktop Module** |

## Screenshots
<p align="center">
  <img src="./assets/screenshot-taskbar.png" width="800" alt="Taskbar Integration">
  <br>
  <em>Integrated into the Windows 11 taskbar.</em>
</p>

<p align="center">
  <img src="./assets/screenshot-devices.png" width="500" alt="Widget Detail">
  <br>
  <em>Dynamic accent colors, polished interface, and one-click device switching.</em>
</p>

## What's New: Device Switching

The widget now has a dedicated cast icon for jumping between Spotify Connect devices (phone, speakers, another computer) without leaving the taskbar. The panel before this update had no way to do this — you can see the extra icon added to the action row below:

<p align="center">
  <img src="./assets/screenshot-comparison.png" width="500" alt="Before and after comparison showing the new device switcher icon">
  <br>
  <em>New (top): device switcher icon added next to Force Reconnect. Previous version (bottom): no way to switch devices from the widget.</em>
</p>

## What's New: Playlists, Search & a Flexible Layout

Beyond switching devices, the widget can now browse and search your library directly:

- **Playlists panel**: A dedicated icon opens your Spotify playlists. Click one to start playing it, or use the arrow on a row to open that playlist and jump straight to a specific song.
- **Liked Songs**: Pinned at the top of the playlist list for one-click access to your saved tracks, with the same browse-to-a-song support.
- **Search**: A search box at the top of the playlist panel finds any song in your Spotify catalog and plays it instantly. Playback doesn't just stop when the song ends either — a handful of tracks from the same artist are queued up afterward.
- **Redesigned device switcher**: The device list is now a floating popup anchored to its icon, opening above the player bar instead of pushing it around.
- **Adjustable layout**: A thin drag handle between the track title and the buttons lets you trade horizontal space between them — more room for long titles, or full-size buttons — without resizing the window itself. Your preference is remembered between sessions.

## Key Features
- **Precision Fit**: Specifically calibrated 40px height for the Windows 11 taskbar.
- **Cross-Platform**: Intelligent positioning for Windows, macOS, and Linux.
- **Dynamic Theming**: Automatic color extraction from album art for visual integration.
- **Device Switching**: Move playback between your phone, speakers, or another computer directly from the widget.
- **Playlists & Search**: Browse your playlists (Liked Songs included), search your Spotify library for a specific song, and jump straight into playback.
- **Adjustable Layout**: Drag a small handle to trade space between the track title and the control buttons to fit your preference.
- **High Performance**: Built with Rust for immediate responsiveness and low resource overhead.
- **Background Operation**: Runs in the system tray to maintain a clean workspace.
- **System Integration**: Global media keys (Play/Pause, Next, Previous), auto-focus on hover, and OS-level secure credential storage.

## Technical Overview
The widget serves as a high-performance remote bridge for your Spotify account. It operates as a standalone application and **does not require the official Spotify desktop client to be open**. 

Utilizing the official Spotify Web API, it synchronizes playback across all your connected devices (mobile, smart speakers, or web player) while consuming significantly fewer resources than the standard desktop client.

## Installation
1. Visit the [Releases](https://github.com/HyphyMike/Spotify-Taskbar-Widget/releases) page.
2. Download `Spotify Taskbar Widget Portable.exe` to run without installing, or one of the Windows installers (`.exe` / `.msi`).
3. Create [config.json](config.example.json) with your own Spotify client ID — see [Configuring the client ID](BUILD-RESULTS.md#configuring-the-client-id).
4. Launch the application and authenticate with your Spotify account.

The taskbar-seating behaviour above is Windows-specific. The app still builds for macOS and Linux from this source, but only the Windows build has been tested and released here.

## Tech Stack
<p align="left">
  <img src="https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white" alt="Rust">
  <img src="https://img.shields.io/badge/Tauri-FFC131?style=for-the-badge&logo=tauri&logoColor=white" alt="Tauri">
  <img src="https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black" alt="JS">
  <img src="https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white" alt="CSS">
</p>

## License
This project is licensed under the MIT License. See the LICENSE file for more information.

---
<p align="center">
  Built for performance and desktop efficiency.
</p>
