import Combine
import Foundation

// MARK: - Scan Path Config Manager

/// 扫描路径状态管理器 - 提供路径状态检查和缓存功能
final class ScanPathConfigManager: ObservableObject {
    static let shared = ScanPathConfigManager()

    /// 路径状态缓存
    @Published private(set) var pathStatuses: [String: PathStatus] = [:]

    private init() {}

    // MARK: - Public Methods

    /// 检查路径状态（同步版本，只能在主线程调用，会更新缓存）
    func checkPathStatus(_ path: String) -> PathStatus {
        if let cached = pathStatuses[path] {
            return cached
        }
        let status = computePathStatus(for: path)
        pathStatuses[path] = status
        return status
    }

    /// 异步检查路径状态。文件 IO 在后台线程，写 @Published 必须回到主线程。
    func checkPathStatusAsync(_ path: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let status = self.computePathStatus(for: path)
            DispatchQueue.main.async {
                self.pathStatuses[path] = status
            }
        }
    }

    /// 刷新指定路径列表的状态
    func refreshPathStatuses(for paths: [String]) {
        for path in paths {
            pathStatuses.removeValue(forKey: path)
            checkPathStatusAsync(path)
        }
    }

    /// 清除路径状态缓存
    func clearStatusCache() {
        pathStatuses.removeAll()
    }

    // MARK: - Private Methods

    /// 纯计算，不读写任何 @Published 状态，可以安全地在后台线程执行。
    private func computePathStatus(for path: String) -> PathStatus {
        return DirectoryAccessManager.shared.withBestAccess(to: [path]) {
        let expandedPath = (path as NSString).expandingTildeInPath
        let fileManager = FileManager.default

        // 处理通配符路径
        if expandedPath.contains("*") {
            let resolvedPaths = resolveWildcardPath(expandedPath)

            if resolvedPaths.isEmpty {
                return PathStatus(exists: false, isAccessible: false, versionCount: 0)
            }

            var validCount = 0
            var allAccessible = true

            for resolved in resolvedPaths {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: resolved, isDirectory: &isDirectory),
                    isDirectory.boolValue
                {
                    validCount += 1
                    if !fileManager.isReadableFile(atPath: resolved) {
                        allAccessible = false
                    }
                }
            }

            return PathStatus(
                exists: validCount > 0,
                isAccessible: validCount > 0 && allAccessible,
                versionCount: validCount
            )
        }

        // 非通配符路径
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: expandedPath, isDirectory: &isDirectory)

        if !exists || !isDirectory.boolValue {
            return PathStatus(exists: false, isAccessible: false, versionCount: nil)
        }

        let isAccessible = fileManager.isReadableFile(atPath: expandedPath)

        // 统计版本数量（只统计目录，不把普通文件算成版本）
        var versionCount: Int? = nil
        if isAccessible,
            let contents = try? fileManager.contentsOfDirectory(atPath: expandedPath)
        {
            versionCount = contents.filter { item in
                guard !item.hasPrefix(".") else { return false }
                var itemIsDirectory: ObjCBool = false
                let itemPath = (expandedPath as NSString).appendingPathComponent(item)
                return fileManager.fileExists(atPath: itemPath, isDirectory: &itemIsDirectory)
                    && itemIsDirectory.boolValue
            }.count
        }

        return PathStatus(
            exists: true, isAccessible: isAccessible, versionCount: versionCount)
        }
    }

    /// 解析通配符路径，返回匹配的实际路径列表
    private func resolveWildcardPath(_ path: String) -> [String] {
        guard path.contains("*") else {
            return [path]
        }

        let fileManager = FileManager.default

        // 处理 Homebrew Cellar 路径 (如 /opt/homebrew/Cellar/python*)
        let cellarRoots = ["/opt/homebrew/Cellar", "/usr/local/Cellar"]
        for root in cellarRoots {
            if path.hasPrefix(root + "/") {
                let remainder = String(path.dropFirst(root.count + 1))
                let prefix = remainder.replacingOccurrences(of: "*", with: "")

                guard let items = try? fileManager.contentsOfDirectory(atPath: root) else {
                    continue
                }

                // 与 CustomVersionManager 的 Homebrew 匹配规则保持一致：
                // python@* 匹配 python@3.13；go* 匹配 go / go@1.22，不匹配 golangci-lint。
                return items.filter { item in
                    if prefix.hasSuffix("@") {
                        return item.hasPrefix(prefix)
                    }
                    return item == prefix || item.hasPrefix(prefix + "@")
                }.map { "\(root)/\($0)" }
            }
        }

        // 处理通用通配符路径 (如 ~/custom/python*)
        let parentPath = (path as NSString).deletingLastPathComponent
        let pattern = (path as NSString).lastPathComponent
        let prefix = pattern.replacingOccurrences(of: "*", with: "")

        guard let items = try? fileManager.contentsOfDirectory(atPath: parentPath) else {
            return []
        }

        return items.filter { $0.hasPrefix(prefix) }
            .map { (parentPath as NSString).appendingPathComponent($0) }
    }
}
