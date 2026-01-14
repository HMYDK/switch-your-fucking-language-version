import AppKit
import Foundation

/// 目录访问管理器 - 实现 Security-Scoped Bookmarks 机制
/// 用于在 App Sandbox 环境下获取用户授权的目录访问权限
class DirectoryAccessManager: ObservableObject {
    static let shared = DirectoryAccessManager()

    /// 已授权的目录 URL 列表
    @Published private(set) var authorizedDirectories: [URL] = []

    /// 是否需要显示引导页面
    @Published var needsOnboarding: Bool = false

    /// UserDefaults key for storing bookmarks
    private let bookmarksKey = "DirectoryBookmarks"

    /// 推荐用户授权的目录路径
    static let recommendedPaths: [(name: String, path: String)] = [
        ("Homebrew (Apple Silicon)", "/opt/homebrew"),
        ("Homebrew (Intel)", "/usr/local"),
        ("NVM Versions", "~/.nvm/versions"),
        ("pyenv Versions", "~/.pyenv/versions"),
        ("GVM Versions", "~/.gvm/gos"),
        ("asdf Installs", "~/.asdf/installs"),
        ("Java VMs", "/Library/Java/JavaVirtualMachines"),
    ]

    private init() {
        loadBookmarks()
        checkOnboardingStatus()
    }

    // MARK: - Public Methods

    /// 检查是否已完成首次设置
    func checkOnboardingStatus() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
        needsOnboarding = !hasCompletedOnboarding && authorizedDirectories.isEmpty
    }

    /// 标记引导已完成
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        needsOnboarding = false
    }

    /// 请求用户授权访问目录
    /// - Parameter suggestedPath: 建议打开的路径
    /// - Returns: 授权的目录 URL，如果用户取消则返回 nil
    @MainActor
    func requestDirectoryAccess(suggestedPath: String? = nil) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Grant Access"
        panel.message =
            "Select a directory to grant RuntimePilot access for scanning installed versions."

        // 设置建议的初始目录
        if let path = suggestedPath {
            let expandedPath = NSString(string: path).expandingTildeInPath
            panel.directoryURL = URL(fileURLWithPath: expandedPath)
        }

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        // 保存 bookmark
        do {
            try saveBookmark(for: url)

            // 更新已授权目录列表
            if !authorizedDirectories.contains(url) {
                authorizedDirectories.append(url)
            }

            return url
        } catch {
            print("Failed to save bookmark: \(error)")
            return nil
        }
    }

    /// 开始访问已授权的目录
    /// - Parameter url: 目录 URL
    /// - Returns: 是否成功开始访问
    func startAccessing(url: URL) -> Bool {
        return url.startAccessingSecurityScopedResource()
    }

    /// 停止访问已授权的目录
    /// - Parameter url: 目录 URL
    func stopAccessing(url: URL) {
        url.stopAccessingSecurityScopedResource()
    }

    /// 执行需要目录访问权限的操作
    /// - Parameters:
    ///   - url: 目录 URL
    ///   - operation: 要执行的操作
    func withAccess<T>(to url: URL, perform operation: () throws -> T) rethrows -> T? {
        guard startAccessing(url: url) else {
            print("Failed to start accessing: \(url.path)")
            return nil
        }
        defer { stopAccessing(url: url) }
        return try operation()
    }

    /// 移除授权的目录
    /// - Parameter url: 要移除的目录 URL
    func removeAuthorization(for url: URL) {
        authorizedDirectories.removeAll { $0 == url }
        saveAllBookmarks()
    }

    /// 检查路径是否在已授权的目录下
    /// - Parameter path: 要检查的路径
    /// - Returns: 是否有访问权限
    func hasAccess(to path: String) -> Bool {
        let expandedPath = NSString(string: path).expandingTildeInPath
        return authorizedDirectories.contains { url in
            expandedPath.hasPrefix(url.path)
        }
    }

    // MARK: - Private Methods

    /// 保存单个目录的 bookmark
    private func saveBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        var bookmarks = loadBookmarkData()
        bookmarks[url.path] = bookmarkData

        UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
    }

    /// 保存所有已授权目录的 bookmarks
    private func saveAllBookmarks() {
        var bookmarks: [String: Data] = [:]

        for url in authorizedDirectories {
            if let bookmarkData = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                bookmarks[url.path] = bookmarkData
            }
        }

        UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
    }

    /// 加载已保存的 bookmarks
    private func loadBookmarks() {
        let bookmarks = loadBookmarkData()
        var loadedURLs: [URL] = []

        for (_, bookmarkData) in bookmarks {
            var isStale = false

            do {
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if isStale {
                    // Bookmark 过期，尝试重新保存
                    try? saveBookmark(for: url)
                }

                loadedURLs.append(url)
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }

        authorizedDirectories = loadedURLs
    }

    /// 从 UserDefaults 加载 bookmark 数据
    private func loadBookmarkData() -> [String: Data] {
        return UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
    }
}
