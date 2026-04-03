<p align="center">
  <img src="MacSetup/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="MacSetup">
</p>

<h1 align="center">MacSetup</h1>

<p align="center">
  The fastest way to provision a new Mac.<br>
  Browse, select, and install all your apps in one shot — no Terminal required.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/swift-5.9-orange?style=flat-square&logo=swift" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-Elastic--2.0-blue?style=flat-square" alt="Elastic License 2.0">
  <img src="https://img.shields.io/badge/built%20with-SwiftUI-purple?style=flat-square" alt="SwiftUI">
</p>

---

## What it does

MacSetup is a native macOS app that replaces the usual post-format ritual of hunting down installers one by one. Pick the apps you want from a curated catalog, hit **Install**, and watch the forge run.

Everything is powered by [Homebrew](https://brew.sh) — MacSetup will walk you through installing it if it isn't already there.

---

## Features

- **Smart detection** — scans `/Applications` and `brew list` on launch; already-installed apps are greyed out automatically
- **Curated catalog** — 30 hand-picked apps across 7 categories: Browsers, Development, AI & LLM, Productivity, Media, Utilities, and CLI Tools
- **Live forge view** — split-pane progress sheet with per-app status, spinning indicators, and color-coded Homebrew logs
- **Search** — filter across all categories instantly from the toolbar
- **Official icons** — pulls each app's real icon from its website, the App Store, or GitHub
- **Homebrew onboarding** — first-run wizard guides users through Homebrew installation before anything else runs
- **Refresh** — re-checks installed status on demand with atomic, flicker-free updates

---

## Download

**[Download MacSetup.dmg](MacSetup.dmg)** — drag to Applications and launch.

> **Gatekeeper warning?**
> macOS quarantines unsigned apps downloaded from the web. After dragging to Applications, run:
> ```zsh
> xattr -cr /Applications/MacSetup.app
> ```
> You only need to do this once.

---

## App Catalog

| Category | Apps |
|---|---|
| Browsers | Dia, Arc, Brave, Chrome |
| Development | VS Code, iTerm2, Xcode, tmux, Antigravity (Google) |
| AI & LLM | Ollama, Codex, Claude |
| Productivity | Notion, Notion Calendar, Notion Mail, Raycast, Webex, LINE, Microsoft Word |
| Media | IINA, Figma, Affinity Publisher 2, Wallpaper Play |
| Utilities | OneDrive, Stats, Surfshark, Citrix Workspace, Logi Options+, MonitorControl Lite, Amphetamine |
| CLI Tools | git, gh, node, yabai |

---

## Requirements

- macOS 14 Sonoma or later
- [Homebrew](https://brew.sh) — prompted on first launch if missing
- Xcode 15+ (to build from source)

---

## Build from Source

```zsh
# Install dependencies
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Open and run
open MacSetup.xcodeproj
```

Press `⌘R` to build and run.

### Build a DMG

```zsh
./make_dmg.sh
```

Outputs `MacSetup.dmg` in the project root — a standard drag-to-Applications installer.

---

## Adding Apps

Open `MacSetup/Models/AppCatalog.swift` and append an `AppItem`:

```swift
AppItem(
    id: UUID(),
    name: "My App",
    category: .utilities,
    method: .brewCask(caskName: "my-app"),
    bundleName: "My App",   // .app bundle name in /Applications
    website: url("https://myapp.com")
)
```

Supported install methods: `.brewCask`, `.brewFormula`, `.appStore(url:)`, `.manual(url:)`.

---

## Contributing

Pull requests are welcome. For major changes, open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Push and open a PR

---

## License

[Elastic License 2.0](LICENSE) © [kayuling](https://github.com/kayuling)

Free to use and modify. You may not offer the software as a hosted/managed service to third parties. See [LICENSE](LICENSE) for the full text.
