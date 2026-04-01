# MacSetup

A native macOS app for setting up a new Mac — browse, select, and install all your apps in one click.

![MacSetup Icon](MacSetup/Assets.xcassets/AppIcon.appiconset/icon_128x128.png)

## Features

- **Auto-detection** — scans `/Applications` and `brew list` on launch to grey out already-installed apps
- **Categorized sidebar** — browse by Browsers, Development, AI & LLM, Productivity, Media, Utilities, and CLI Tools with color-coded icons
- **Search** — quickly find apps across all categories from the toolbar
- **One-click install** — runs `brew reinstall --cask` / `brew reinstall` for all selected apps sequentially
- **Live terminal output** — split-pane progress sheet with circular progress ring and color-coded brew logs
- **Official app icons** — fetches icons from each app's official website, iTunes, or GitHub
- **Hover interactions** — card-style rows with hover effects and contextual website links
- **Homebrew onboarding** — prompts new users to install Homebrew before first use
- **Refresh** — re-scans installed status on demand with glitch-free atomic updates

## App Catalog (30 apps)

| Category | Apps |
|---|---|
| Browsers | Dia, Arc, Brave, Chrome |
| Development | VS Code, iTerm2, Xcode, cmux, Antigravity (Google) |
| AI & LLM | Ollama, Codex, Claude |
| Productivity | Notion, Notion Calendar, Notion Mail, Raycast, Webex, LINE, Microsoft Word |
| Media | IINA, Figma, Affinity Publisher 2, Wallpaper Play |
| Utilities | OneDrive, Stats, Surfshark, Citrix Workspace, Logi Options+, MonitorControl Lite, Amphetamine |
| CLI Tools | git, gh, node, yabai |

## Quick Install

1. Download **[MacSetup.dmg](MacSetup.dmg)**
2. Open the DMG and drag **MacSetup.app** into your Applications folder
3. Launch MacSetup from Applications or Spotlight
4. If prompted, install Homebrew first — the app will walk you through it
5. Select the apps you want, click **Install** — done

> **"MacSetup.app is damaged and can't be opened"**
> macOS quarantines apps downloaded from the internet that aren't notarized by Apple. To fix, run this in Terminal **after dragging to Applications**:
> ```zsh
> xattr -cr /Applications/MacSetup.app
> ```
> This removes the quarantine flag and the app will open normally. You only need to do this once.

## Requirements

- macOS 14 (Sonoma) or later
- [Homebrew](https://brew.sh) — the app will prompt you to install it on first launch if missing
- Xcode 15+ (to build from source)

## Build from Source

```zsh
# Install dependencies
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open MacSetup.xcodeproj
```

Then press `⌘R` to build and run.

## Build a DMG

```zsh
./make_dmg.sh
```

Produces `MacSetup.dmg` in the project root — a standard drag-to-Applications installer.

## Adding Apps

Edit `MacSetup/Models/AppCatalog.swift` and add an `AppItem` entry:

```swift
AppItem(
    id: UUID(),
    name: "My App",
    category: .utilities,
    method: .brewCask(caskName: "my-app"),
    bundleName: "My App",          // .app name in /Applications (for installed detection)
    website: url("https://myapp.com")
)
```

Install methods: `.brewCask`, `.brewFormula`, `.appStore(url:)`, `.manual(url:)`.
