import Foundation

struct AppCatalog {
    static let all: [AppItem] = brewCasks + brewFormulas + appStoreItems + manualItems

    // MARK: - Brew Casks

    private static let brewCasks: [AppItem] = [
        // Browsers
        AppItem(id: UUID(), name: "Dia",                  category: .browsers,      method: .brewCask(caskName: "thebrowsercompany-dia"),  bundleName: "Dia",                  website: url("https://diabrowser.com")),
        AppItem(id: UUID(), name: "Arc",                  category: .browsers,      method: .brewCask(caskName: "arc"),                   bundleName: "Arc",                  website: url("https://arc.net")),
        AppItem(id: UUID(), name: "Brave Browser",        category: .browsers,      method: .brewCask(caskName: "brave-browser"),          bundleName: "Brave Browser",        website: url("https://brave.com")),
        AppItem(id: UUID(), name: "Google Chrome",        category: .browsers,      method: .brewCask(caskName: "google-chrome"),          bundleName: "Google Chrome",        website: url("https://www.google.com/chrome")),
        // Development
        AppItem(id: UUID(), name: "VS Code",              category: .dev,           method: .brewCask(caskName: "visual-studio-code"),     bundleName: "Visual Studio Code",   website: url("https://code.visualstudio.com")),
        AppItem(id: UUID(), name: "iTerm2",               category: .dev,           method: .brewCask(caskName: "iterm2"),                 bundleName: "iTerm",                website: url("https://iterm2.com")),
        AppItem(id: UUID(), name: "Figma",                category: .dev,           method: .brewCask(caskName: "figma"),                  bundleName: "Figma",                website: url("https://www.figma.com")),
        // AI & LLM
        AppItem(id: UUID(), name: "Ollama",               category: .ai,            method: .brewCask(caskName: "ollama"),                 bundleName: "Ollama",               website: url("https://ollama.com")),
        AppItem(id: UUID(), name: "Codex",                category: .ai,            method: .brewCask(caskName: "codex"),                  bundleName: "Codex",                website: url("https://github.com/openai/codex")),
        // Productivity
        AppItem(id: UUID(), name: "Notion",               category: .productivity,  method: .brewCask(caskName: "notion"),                 bundleName: "Notion",               website: url("https://www.notion.so")),
        AppItem(id: UUID(), name: "Notion Calendar",      category: .productivity,  method: .brewCask(caskName: "notion-calendar"),        bundleName: "Notion Calendar",      website: url("https://www.notion.so")),
        AppItem(id: UUID(), name: "Notion Mail",          category: .productivity,  method: .brewCask(caskName: "notion-mail"),            bundleName: "Notion Mail",          website: url("https://www.notion.so/product/mail")),
        AppItem(id: UUID(), name: "Raycast",              category: .productivity,  method: .brewCask(caskName: "raycast"),                bundleName: "Raycast",              website: url("https://www.raycast.com")),
        AppItem(id: UUID(), name: "OneDrive",             category: .productivity,  method: .brewCask(caskName: "onedrive"),               bundleName: "OneDrive",             website: url("https://www.microsoft.com/en-us/microsoft-365/onedrive")),
        // Media
        AppItem(id: UUID(), name: "IINA",                 category: .media,         method: .brewCask(caskName: "iina"),                   bundleName: "IINA",                 website: url("https://iina.io")),
        AppItem(id: UUID(), name: "Affinity Publisher 2", category: .media,         method: .brewCask(caskName: "affinity-publisher-2"),   bundleName: "Affinity",             website: url("https://affinity.serif.com")),
        // Utilities
        AppItem(id: UUID(), name: "Stats",                category: .utilities,     method: .brewCask(caskName: "stats"),                  bundleName: "Stats",                website: url("https://github.com/exelban/stats")),
        AppItem(id: UUID(), name: "Surfshark",            category: .utilities,     method: .brewCask(caskName: "surfshark"),              bundleName: "Surfshark",            website: url("https://surfshark.com")),
        AppItem(id: UUID(), name: "Webex",                category: .utilities,     method: .brewCask(caskName: "webex"),                  bundleName: "Webex",                website: url("https://www.webex.com")),
        AppItem(id: UUID(), name: "Citrix Workspace",     category: .utilities,     method: .brewCask(caskName: "citrix-workspace"),       bundleName: "Citrix Workspace",     website: url("https://www.citrix.com/downloads/workspace-app/")),
        AppItem(id: UUID(), name: "Logi Options+",        category: .utilities,     method: .brewCask(caskName: "logi-options+"),          bundleName: "logioptionsplus",      website: url("https://www.logitech.com")),
        AppItem(id: UUID(), name: "MonitorControl Lite",  category: .utilities,     method: .brewCask(caskName: "monitor-control-lite"),   bundleName: "MonitorControlLite",   website: url("https://github.com/MonitorControl/MonitorControl")),
    ]

    // MARK: - Brew Formulas (CLI Tools)

    private static let brewFormulas: [AppItem] = [
        AppItem(id: UUID(), name: "git",        category: .cli, method: .brewFormula(formulaName: "git"),        website: url("https://git-scm.com")),
        AppItem(id: UUID(), name: "gh",         category: .cli, method: .brewFormula(formulaName: "gh"),         website: url("https://cli.github.com")),
        AppItem(id: UUID(), name: "node",       category: .cli, method: .brewFormula(formulaName: "node"),       website: url("https://nodejs.org")),
        AppItem(id: UUID(), name: "ripgrep",    category: .cli, method: .brewFormula(formulaName: "ripgrep"),    website: url("https://github.com/BurntSushi/ripgrep")),
        AppItem(id: UUID(), name: "ffmpeg",     category: .cli, method: .brewFormula(formulaName: "ffmpeg"),     website: url("https://ffmpeg.org")),
        AppItem(id: UUID(), name: "pandoc",     category: .cli, method: .brewFormula(formulaName: "pandoc"),     website: url("https://pandoc.org")),
        AppItem(id: UUID(), name: "yabai",      category: .cli, method: .brewFormula(formulaName: "yabai"),      website: url("https://github.com/koekeishiya/yabai")),
        AppItem(id: UUID(), name: "supabase",   category: .cli, method: .brewFormula(formulaName: "supabase"),   website: url("https://supabase.com")),
        AppItem(id: UUID(), name: "gemini-cli", category: .cli, method: .brewFormula(formulaName: "gemini-cli"), website: url("https://github.com/google-gemini/gemini-cli")),
        AppItem(id: UUID(), name: "opencode",   category: .cli, method: .brewFormula(formulaName: "opencode"),   website: url("https://opencode.ai")),
    ]

    // MARK: - App Store

    private static let appStoreItems: [AppItem] = [
        AppItem(id: UUID(), name: "Xcode",          category: .appStore, method: .appStore(url: url("macappstore://apps.apple.com/app/id497799835")!),  bundleName: "Xcode",          website: url("macappstore://apps.apple.com/app/id497799835")),
        AppItem(id: UUID(), name: "Amphetamine",    category: .appStore, method: .appStore(url: url("macappstore://apps.apple.com/app/id937984704")!),  bundleName: "Amphetamine",    website: url("macappstore://apps.apple.com/app/id937984704")),
        AppItem(id: UUID(), name: "LINE",           category: .appStore, method: .appStore(url: url("macappstore://apps.apple.com/app/id539883307")!),  bundleName: "LINE",           website: url("macappstore://apps.apple.com/app/id539883307")),
        AppItem(id: UUID(), name: "Wallpaper Play", category: .appStore, method: .appStore(url: url("macappstore://apps.apple.com/app/id1417837810")!), bundleName: "Wallpaper Play", website: url("macappstore://apps.apple.com/app/id1417837810")),
    ]

    // MARK: - Manual Downloads

    private static let manualItems: [AppItem] = [
        AppItem(id: UUID(), name: "Claude",         category: .manual, method: .manual(url: url("https://claude.ai/downloads")!), bundleName: "Claude",        website: url("https://claude.ai/downloads")),
        AppItem(id: UUID(), name: "Microsoft Word", category: .manual, method: .manual(url: url("https://www.microsoft.com")!), bundleName: "Microsoft Word", website: url("https://www.microsoft.com/en-us/microsoft-365/word")),
        AppItem(id: UUID(), name: "Antigravity",    category: .manual, method: .manual(url: url("https://antigravity.google/")!), bundleName: "Antigravity",   website: url("https://antigravity.google/")),
        AppItem(id: UUID(), name: "cmux",           category: .manual, method: .manual(url: url("https://github.com")!),        bundleName: "cmux",          website: nil),
    ]

    // MARK: - Helper

    private static func url(_ string: String) -> URL? { URL(string: string) }
}
