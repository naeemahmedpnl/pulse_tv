<div align="center">

# ⚡ Pulse TV

### High-Performance Live IPTV Streaming Platform for Android TV, Web, macOS & Mobile
*Engineered with Flutter, BLoC / Cubit Reactive State Management, and MediaKit*

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/State_Management-BLoC_/_Cubit-7928CA?style=for-the-badge&logo=bloc&logoColor=white)](https://bloclibrary.dev)
[![Engine](https://img.shields.io/badge/Video_Engine-MediaKit_HLS-00E5FF?style=for-the-badge&logo=vlc&logoColor=black)](https://github.com/media-kit/media-kit)
[![Platforms](https://img.shields.io/badge/Platforms-Android_TV_|_Web_|_macOS_|_Mobile-22C55E?style=for-the-badge)](https://flutter.dev)

</div>

---

## 📺 Overview

**Pulse TV** is a broadcast-grade, ultra-modern Live IPTV streaming application purpose-built for widescreen 10-foot Android TV experiences, desktop web browsers, macOS, and mobile devices. 

Designed with an **Agentic Cyber-Glassmorphic aesthetic**, Pulse TV delivers zero-latency channel switching, persistent logo caching for 0ms recall, a logo-first visual browsing experience, and a floating cinema-grade player controls HUD.

---

## ✨ Key Features

### 🇵🇰 🇮🇳 Curated Pakistan & India HD Broadcasts
* **Pre-Configured Streams**: Direct integration with verified open IPTV live streams for Pakistan (`pk.m3u`) and India (`in.m3u`).
* **Intelligent Resolution Filter**: Automatically eliminates SD and low-bitrate streams (`576p`, `480p`, `360p`), prioritizing crystal-clear **1080p Full HD**, **720p HD**, and **4K** feeds.
* **Country Flags & Badges**: Distinct country badges (`🇵🇰 PK` / `🇮🇳 IN`) with visual quality markers (`1080p`, `720p`, `4K`).

### 🖼️ Logo-First Visual Interface & Persistent Caching
* **Prominent Channel Logos**: Cards and strips feature prominent channel branding rather than text clutter.
* **0ms Instant Logo Recall**: Equipped with `LogoCacheService` which automatically pre-warms and downloads channel logos into memory in the background.
* **High-Capacity Image Cache**: Extended RAM cache (`3,000 images / 250MB`) ensures smooth 60/120 FPS scrolling with zero network re-fetching.
* **Dynamic Broadcast Fallback**: Beautiful dual-color branded gradient badges with channel initials if an external logo URL is unreachable.

### 🎮 Modern Floating Cyber Player Controls HUD
* **Glassmorphic Floating Dock**: Frosted backdrop blur (`BackdropFilter(sigma: 28)`) with cyan-purple glowing edge reflections.
* **Cyber Play/Pause Center**: Glowing 60px gradient play button with animated ripple focus rings.
* **Instant Aspect Ratio Switcher**: One-click cycling between **16:9 Fit**, **Zoom Fullscreen (Fill)**, and **Stretch**, complete with real-time on-screen toast feedback.
* **Interactive Volume & Mute**: Direct volume slider with real-time percentage readout and instant mute toggle.
* **Telemetry & Stream Health**: Real-time indicator featuring pulsing `🔴 LIVE` beacon, `1080p 60FPS` badge, and `AI Zero-Jitter Ultra-Low Latency` diagnostics.
* **Channel Guide Strip**: Horizontal live carousel overlay with equalizer animation on the actively playing channel.
* **Auto-Hide Cinema Mode**: Player HUD auto-fades after 5 seconds of inactivity and smoothly re-appears on remote keypress, touch, or mouse movement.

---

## 🏗️ State Management Architecture (BLoC / Cubit)

Pulse TV utilizes **Cubit** from the [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) library for ultra-fast, predictable, stream-based reactive state management.

```
       ┌──────────────────────┐
       │   PlaylistService    │  (Fetches & parses PK/IN M3U feeds)
       └──────────┬───────────┘
                  │
                  ▼
       ┌──────────────────────┐
       │     ChannelCubit     │◄─── User Actions (Favorites, Recents, Sources)
       └──────────┬───────────┘
                  │ Emits immutable state
                  ▼
       ┌──────────────────────┐
       │     ChannelState     │  (Channels, Groups, Favorites, Recent, Loading)
       └──────────┬───────────┘
                  │
       ┌──────────┴───────────┐
       ▼                      ▼
┌──────────────┐      ┌──────────────┐
│ BlocBuilder  │      │ context.watch│ (Reactive UI Rebuilds)
└──────────────┘      └──────────────┘
```

### Why Cubit?
1. **Lightweight & High Performance**: Avoids redundant event-transformer overhead of full BLoC while providing strict unidirectional data flow.
2. **Instant Local Storage Recall**: Cold-boots directly from `SharedPreferences` cache in **0ms** while refreshing live channel states in the background.
3. **Immutability & Safety**: All state changes produce a new `ChannelState` with `copyWith`, making debugging and telemetry effortless.

---

## 🎮 Remote Control & Keyboard Navigation

Pulse TV is fully navigable via Android TV D-Pad remotes, standard keyboards, and touch/mouse inputs:

| Action | TV Remote Key | Keyboard Shortcut | Touch / Mouse |
|---|---|---|---|
| **Next Channel** | `▲` / `Channel Up` | `▲` (Up Arrow) | Swipe Up / Click Next (`⏭`) |
| **Previous Channel** | `▼` / `Channel Down` | `▼` (Down Arrow) | Swipe Down / Click Prev (`⏮`) |
| **Play / Pause** | `Select` / `Play/Pause` | `Space` / `K` | Click Center Play Button (`⏯`) |
| **Volume Up / Down** | `Volume Up / Down` | `◀` / `▶` (Left / Right) | Drag Volume Slider |
| **Mute / Unmute** | `Mute` | `M` | Click Volume Speaker Icon |
| **Cycle Aspect Ratio** | — | `A` | Click Aspect Ratio Pill |
| **Toggle Channel Guide** | `OK` / `Enter` | `G` / `Enter` | Click `Guide` Pill / Tap Video |
| **Toggle Favorite** | `Context Menu` / `Yellow` | `F` | Click Heart Icon (`❤️`) |
| **Back / Exit** | `Back` | `Escape` / `Backspace` | Click Top-Left Back Arrow (`←`) |

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App initialization, MediaKit setup & high-capacity image cache
├── theme.dart                 # Glassmorphic color tokens, Outfit typography & gradients
├── app_state.dart             # AppScope bridge & BuildContext extensions for Cubit
│
├── bloc/
│   ├── channel_cubit.dart     # Business logic, caching, favorites, and live updates
│   └── channel_state.dart     # Immutable ChannelState with helper queries & filters
│
├── models/
│   └── channel.dart           # Channel model with HD detection, country flags & headers
│
├── services/
│   ├── playlist_service.dart  # M3U parser, IPTV-org fetcher, and local storage cache
│   └── logo_cache_service.dart# Background logo pre-warming & multi-batch disk caching
│
├── screens/
│   ├── home_screen.dart       # Hero banner, category rails & discovery chips
│   ├── browse_screen.dart     # Grid view, search engine, country tabs & favorites
│   ├── player_screen.dart     # Modern fullscreen player with cyber controls HUD
│   └── settings_screen.dart   # Playlist management, source URLs, and cache diagnostics
│
└── widgets/
    ├── common.dart            # ChannelCard, ChannelLogo, LiveBadge, PillButton, ClockText
    ├── focus_card.dart        # TV D-pad focus handler with scale, glow & smooth scroll
    └── side_nav.dart          # Collapsible TV leanback sidebar with glowing active indicators
```

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.24.0`)
* Android Studio / Xcode (for Android TV or macOS deployments)
* Google Chrome (for Web deployment)

### 1. Clone & Install
```bash
git clone https://github.com/your-username/pulse_tv.git
cd pulse_tv
flutter pub get
```

### 2. Run on Web (Chrome)
To run on Chrome with multi-origin HLS live streaming support:
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### 3. Run on macOS Desktop
```bash
flutter run -d macos
```

### 4. Build for Android TV & FireStick
Pulse TV includes native Android TV Leanback configurations (`minSdk 21`, `usesCleartextTraffic`, `LEANBACK_LAUNCHER`).

To build optimized APKs for Android TV boxes, FireTV sticks, and NVIDIA Shield:
```bash
flutter build apk --release --split-per-abi
```
*Output APKs will be generated in `build/app/outputs/flutter-apk/`:*
* `app-arm64-v8a-release.apk` (Modern 64-bit Android TV devices)
* `app-armeabi-v7a-release.apk` (Fire TV Sticks & 32-bit legacy boxes)

---

## 🛡️ License

Pulse TV is licensed under the **MIT License**. Stream content is sourced from open-access IPTV directories (`iptv-org`).
