# Contributing to Pulse TV ⚡

First off, thank you for considering contributing to **Pulse TV**! Whether you are a Flutter engineer, UI/UX designer, or Android TV enthusiast, your help is welcome.

---

## 🚀 How to Contribute

### 1. Reporting Bugs & Suggesting Features
- Check the [Issues tab](https://github.com/naeemahmedpnl/pulse_tv/issues) to ensure your idea or bug hasn't already been reported.
- Open a new issue with a clear description, reproduction steps, and screenshots/recordings if applicable.

### 2. Working on Code
1. **Fork** the repository to your own GitHub account.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/pulse_tv.git
   cd pulse_tv
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Implement your changes and ensure no analysis errors:
   ```bash
   flutter analyze
   ```
6. Commit with clear, descriptive messages:
   ```bash
   git commit -m "feat: add EPG electronic program guide support"
   ```
7. Push to your branch and open a **Pull Request (PR)** against the `main` branch.

---

## 🎯 What We Need Help With (Roadmap)

We are actively seeking contributions in:
- [ ] **EPG (Electronic Program Guide)**: XMLTV format parser for live TV schedules.
- [ ] **Multiple Audio & Subtitle Track Selector**: Native UI for switching languages in `player_screen.dart`.
- [ ] **Custom Playlist Ingestion**: Add M3U playlist via QR code or local file upload.
- [ ] **Additional Country Filters**: Support for UK, US, MENA, and European IPTV channels.
- [ ] **Apple TV / tvOS Support**: Extending the Flutter codebase to Apple TV.
- [ ] **PiP (Picture-in-Picture)**: Native Android TV / Mobile PiP support.
- [ ] **UI/UX Themes**: Cyberpunk, Midnight OLED, and Pure Glass customization options.

---

## 🎨 Code Style Guidelines

- Follow official [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.
- Use **BLoC / Cubit** for business logic and state management. Keep widgets declarative and focused.
- Ensure TV D-pad focus (`FocusCard` / `Focus`) is supported on any new interactive elements.

Thank you for helping make Pulse TV the best open-source live TV experience!
