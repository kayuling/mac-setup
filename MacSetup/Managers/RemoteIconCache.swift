import AppKit
import Foundation

/// Fetches and caches app icons from the internet.
///
/// Strategy per install method:
/// - brewFormula (CLI):  GitHub avatar → Clearbit logo
/// - brewCask / manual:  iTunes Search → GitHub avatar → Clearbit logo
/// - appStore:           iTunes Search (most accurate for App Store apps)
@MainActor
final class RemoteIconCache {
    static let shared = RemoteIconCache()
    private init() {}

    private var cache: [UUID: NSImage] = [:]
    private var inFlight: Set<UUID> = []

    func cachedIcon(for item: AppItem) -> NSImage? {
        cache[item.id]
    }

    func fetchIcon(for item: AppItem) async -> NSImage? {
        if let cached = cache[item.id] { return cached }
        guard !inFlight.contains(item.id) else { return nil }
        inFlight.insert(item.id)
        defer { inFlight.remove(item.id) }

        let image: NSImage? = await resolveIcon(for: item)
        if let image { cache[item.id] = image }
        return image
    }

    // MARK: - Strategy routing

    private func resolveIcon(for item: AppItem) async -> NSImage? {
        switch item.method {
        case .brewFormula:
            // iTunes Search returns random GUI apps for CLI tool names — skip it.
            // Try GitHub org avatar first (great for github.com-hosted tools).
            if let website = item.website, let img = await fetchGitHubAvatar(from: website) { return img }
            if let website = item.website, let host = strippedHost(website),
               let img = await fetchClearbitIcon(domain: host) { return img }

        case .brewCask, .manual:
            if let img = await fetchItunesIcon(name: item.name) { return img }
            if let website = item.website, let img = await fetchGitHubAvatar(from: website) { return img }
            if let website = item.website, let host = strippedHost(website),
               let img = await fetchClearbitIcon(domain: host) { return img }

        case .appStore:
            // macappstore:// URLs have no domain for Clearbit; iTunes is the right source.
            if let img = await fetchItunesIcon(name: item.name) { return img }
        }
        return nil
    }

    // MARK: - Fetchers

    /// For github.com/<org>/<repo> URLs, fetches the org's GitHub avatar (128px).
    private func fetchGitHubAvatar(from website: URL) async -> NSImage? {
        guard website.scheme == "https",
              website.host() == "github.com" else { return nil }
        let parts = website.pathComponents.filter { $0 != "/" }
        guard let org = parts.first, !org.isEmpty else { return nil }
        guard let url = URL(string: "https://avatars.githubusercontent.com/\(org)?size=128"),
              let (data, _) = try? await URLSession.shared.data(from: url)
        else { return nil }
        return NSImage(data: data)
    }

    /// Searches the iTunes/Mac App Store catalog by app name, returns 512px artwork.
    private func fetchItunesIcon(name: String) async -> NSImage? {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=macSoftware&country=us&limit=5&media=software")
        else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]]
        else { return nil }

        let best = results.first(where: {
            ($0["trackName"] as? String)?.lowercased() == name.lowercased()
        }) ?? results.first

        guard let iconURLStr = best?["artworkUrl512"] as? String ?? best?["artworkUrl100"] as? String,
              let iconURL = URL(string: iconURLStr),
              let (imgData, _) = try? await URLSession.shared.data(from: iconURL)
        else { return nil }

        return NSImage(data: imgData)
    }

    /// Fetches the company/product logo via Clearbit's logo API.
    private func fetchClearbitIcon(domain: String) async -> NSImage? {
        guard domain.contains("."),
              let url = URL(string: "https://logo.clearbit.com/\(domain)?size=128")
        else { return nil }

        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }

        return NSImage(data: data)
    }

    // MARK: - Helpers

    /// Strips "www." prefix from a URL's host for cleaner Clearbit lookups.
    private func strippedHost(_ url: URL) -> String? {
        guard let host = url.host(), !host.isEmpty else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
