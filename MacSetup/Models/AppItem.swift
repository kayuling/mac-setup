import Foundation
import SwiftUI

enum AppCategory: String, CaseIterable, Identifiable {
    case all          = "All"
    case browsers     = "Browsers"
    case dev          = "Development"
    case ai           = "AI & LLM"
    case productivity = "Productivity"
    case media        = "Media"
    case utilities    = "Utilities"
    case cli          = "CLI Tools"
    case appStore     = "App Store"
    case manual       = "Manual"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all:          return "square.grid.2x2"
        case .browsers:     return "globe"
        case .dev:          return "terminal"
        case .ai:           return "brain"
        case .productivity: return "checklist"
        case .media:        return "play.rectangle"
        case .utilities:    return "wrench.and.screwdriver"
        case .cli:          return "apple.terminal"
        case .appStore:     return "bag"
        case .manual:       return "arrow.down.circle"
        }
    }
}

enum InstallMethod {
    case brewCask(caskName: String)
    case brewFormula(formulaName: String)
    case appStore(url: URL)
    case manual(url: URL)

    var badgeLabel: String {
        switch self {
        case .brewCask:    return "Cask"
        case .brewFormula: return "Formula"
        case .appStore:    return "App Store"
        case .manual:      return "Manual"
        }
    }

    var badgeColor: Color {
        switch self {
        case .brewCask:    return .blue
        case .brewFormula: return .green
        case .appStore:    return .indigo
        case .manual:      return .orange
        }
    }
}

enum InstallStatus: Equatable {
    case notInstalled
    case alreadyInstalled
    case pending
    case installing
    case done
    case failed(String)
}

struct AppItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: AppCategory
    let method: InstallMethod
    /// The `.app` bundle name (without extension) to check in `/Applications`.
    let bundleName: String?

    /// Official product website, shown as a clickable link in the app list.
    let website: URL?

    init(id: UUID, name: String, category: AppCategory, method: InstallMethod, bundleName: String? = nil, website: URL? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.method = method
        self.bundleName = bundleName
        self.website = website
    }

    static func == (lhs: AppItem, rhs: AppItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
