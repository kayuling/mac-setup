import AppKit
import Foundation

/// Fetches and caches app icons from the internet.
///
/// Resolution priority (after checking local /Applications):
/// 1. Apple-touch-icon from the app's official website (most reliable)
/// 2. iTunes Search with strict exact-name matching
/// 3. GitHub org avatar (for github.com-hosted projects)
/// 4. Clearbit company logo (fallback)
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
            // CLI tools aren't on the App Store — try website sources only.
            if let website = item.website, let img = await fetchWebsiteIcon(from: website) { return img }
            if let website = item.website, let img = await fetchGitHubAvatar(from: website) { return img }
            if let website = item.website, let host = strippedHost(website),
               let img = await fetchClearbitIcon(domain: host) { return img }

        case .brewCask, .manual:
            // Prefer the official website icon, then iTunes strict match, then fallbacks.
            if let website = item.website, let img = await fetchWebsiteIcon(from: website) { return img }
            if let img = await fetchItunesIcon(name: item.name) { return img }
            if let website = item.website, let img = await fetchGitHubAvatar(from: website) { return img }
            if let website = item.website, let host = strippedHost(website),
               let img = await fetchClearbitIcon(domain: host) { return img }

        case .appStore:
            // App Store apps are best resolved via iTunes Search.
            if let img = await fetchItunesIcon(name: item.name) { return img }
        }
        return nil
    }

    // MARK: - Fetchers

    /// Fetches the apple-touch-icon from a website, which is the official high-res icon
    /// most sites provide. Falls back to Google's favicon service.
    private func fetchWebsiteIcon(from website: URL) async -> NSImage? {
        // Skip non-HTTP(S) URLs (e.g. macappstore://)
        guard let scheme = website.scheme, ["http", "https"].contains(scheme),
              let host = website.host(), !host.isEmpty else { return nil }

        // Try standard apple-touch-icon paths (most sites serve a 180px+ icon here)
        let baseURL = "\(scheme)://\(host)"
        let touchIconPaths = [
            "\(baseURL)/apple-touch-icon.png",
            "\(baseURL)/apple-touch-icon-precomposed.png",
        ]

        for path in touchIconPaths {
            if let url = URL(string: path),
               let (data, response) = try? await URLSession.shared.data(from: url),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
               contentType.contains("image"),
               let image = NSImage(data: data),
               image.size.width >= 32 {
                return image
            }
        }

        // Fall back to Google's favicon service (128px)
        if let url = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128"),
           let (data, response) = try? await URLSession.shared.data(from: url),
           let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200,
           let image = NSImage(data: data),
           image.size.width >= 32 {
            return image
        }

        return nil
    }

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
    /// Only returns a result for exact name matches to avoid wrong icons.
    private func fetchItunesIcon(name: String) async -> NSImage? {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=macSoftware&country=us&limit=5&media=software")
        else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]]
        else { return nil }

        // Strict match only — never fall back to a random result
        let best = results.first(where: {
            ($0["trackName"] as? String)?.lowercased() == name.lowercased()
        })

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

    /// Strips "www." prefix from a URL's host for cleaner lookups.
    private func strippedHost(_ url: URL) -> String? {
        guard let host = url.host(), !host.isEmpty else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
