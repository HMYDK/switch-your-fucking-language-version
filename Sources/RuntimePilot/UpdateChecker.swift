import AppKit
import Foundation

// MARK: - GitHub Release Model

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let htmlUrl: String
    let publishedAt: String
    let prerelease: Bool
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case prerelease
        case body
    }

    var version: String {
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }
}

// MARK: - Update Info

struct UpdateInfo {
    let currentVersion: String
    let latestVersion: String
    let releaseUrl: String
    let releaseNotes: String?
    let isUpdateAvailable: Bool
}

// MARK: - Update Checker

@MainActor
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published var updateInfo: UpdateInfo?
    @Published var isChecking = false
    @Published var lastCheckDate: Date?
    @Published var checkError: String?

    // Configure your GitHub repository here
    private let owner = "HMYDK"  // TODO: Replace with actual GitHub username
    private let repo = "RuntimePilot"  // TODO: Replace with actual repo name

    private let checkInterval: TimeInterval = 24 * 60 * 60  // 24 hours

    private init() {}

    var currentVersion: String {
        AppInfo.version
    }

    // MARK: - Public Methods

    func checkForUpdates(force: Bool = false) async {
        // Skip if already checking
        guard !isChecking else { return }

        // Skip if checked recently (unless forced)
        if !force, let lastCheck = lastCheckDate {
            let elapsed = Date().timeIntervalSince(lastCheck)
            if elapsed < checkInterval {
                return
            }
        }

        isChecking = true
        checkError = nil

        defer {
            isChecking = false
            lastCheckDate = Date()
        }

        do {
            let release = try await fetchLatestRelease()

            let isNewer = compareVersions(release.version, currentVersion) > 0

            updateInfo = UpdateInfo(
                currentVersion: currentVersion,
                latestVersion: release.version,
                releaseUrl: release.htmlUrl,
                releaseNotes: release.body,
                isUpdateAvailable: isNewer && !release.prerelease
            )
        } catch let error as NSError where error.domain == "UpdateChecker" && error.code == 404 {
            // No releases yet - this is normal for new projects
            // Show "up to date" status
            updateInfo = UpdateInfo(
                currentVersion: currentVersion,
                latestVersion: currentVersion,
                releaseUrl: "https://github.com/\(owner)/\(repo)/releases",
                releaseNotes: nil,
                isUpdateAvailable: false
            )
        } catch {
            // Only log real errors, not 404
            checkError = error.localizedDescription
            #if DEBUG
                print("Update check failed: \(error)")
            #endif
        }
    }

    func openReleasePage() {
        guard let urlString = updateInfo?.releaseUrl,
            let url = URL(string: urlString)
        else { return }
        NSWorkspace.shared.open(url)
    }

    func dismissUpdate() {
        updateInfo = nil
    }

    // MARK: - Private Methods

    private func fetchLatestRelease() async throws -> GitHubRelease {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw NSError(
                    domain: "UpdateChecker", code: 404,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No releases found"
                    ])
            }
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    /// Compare two semantic version strings
    /// Returns: > 0 if v1 > v2, < 0 if v1 < v2, 0 if equal
    private func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(parts1.count, parts2.count)

        for i in 0..<maxLength {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0

            if p1 != p2 {
                return p1 - p2
            }
        }

        return 0
    }
}
