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

    /// 检查路径状态
    func checkPathStatus(_ path: String) -> PathStatus {
        if let cached = pathStatuses[path] {
            return cached
        }

        let expandedPath = (path as NSString).expandingTildeInPath
        let fileManager = FileManager.default

        // 处理通配符路径
        if expandedPath.contains("*") {
            let resolvedPaths = resolveWildcardPath(expandedPath)

            if resolvedPaths.isEmpty {
                let status = PathStatus(exists: false, isAccessible: false, versionCount: 0)
                pathStatuses[path] = status
                return status
            }

            // 统计有效目录数量并检查可访问性
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

            let status = PathStatus(
                exists: validCount > 0,
                isAccessible: allAccessible,
                versionCount: validCount
            )
            pathStatuses[path] = status
            return status
        }

        // 非通配符路径的原有逻辑
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: expandedPath, isDirectory: &isDirectory)

        if !exists || !isDirectory.boolValue {
            let status = PathStatus(exists: false, isAccessible: false, versionCount: nil)
            pathStatuses[path] = status
            return status
        }

        // 检查是否可访问
        let isAccessible = fileManager.isReadableFile(atPath: expandedPath)

        // 统计版本数量（目录下的子文件夹数）
        var versionCount: Int? = nil
        if isAccessible {
            if let contents = try? fileManager.contentsOfDirectory(atPath: expandedPath) {
                versionCount = contents.filter { !$0.hasPrefix(".") }.count
            }
        }

        let status = PathStatus(
            exists: true, isAccessible: isAccessible, versionCount: versionCount)
        pathStatuses[path] = status
        return status
    }

    /// 异步检查路径状态
    func checkPathStatusAsync(_ path: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let status = self?.checkPathStatus(path) ?? .unknown
            DispatchQueue.main.async {
                self?.pathStatuses[path] = status
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

    /// 解析通配符路径，返回匹配的实际路径列表
    private func resolveWildcardPath(_ path: String) -> [String] {
        // 检查是否包含通配符
        guard path.contains("*") else {
            return [path]
        }

        let fileManager = FileManager.default

        // 处理 Homebrew Cellar 路径 (如 /opt/homebrew/Cellar/python*)
        let cellarRoots = ["/opt/homebrew/Cellar", "/usr/local/Cellar"]
        for root in cellarRoots {
            if path.hasPrefix(root + "/") {
                // 提取前缀 (如 "python" 从 "/opt/homebrew/Cellar/python*")
                let remainder = String(path.dropFirst(root.count + 1))
                let prefix = remainder.replacingOccurrences(of: "*", with: "")

                // 扫描匹配的 formula 目录
                guard let items = try? fileManager.contentsOfDirectory(atPath: root) else {
                    continue
                }

                return items.filter { item in
                    item == prefix || item.hasPrefix("\(prefix)@") || item.hasPrefix(prefix)
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
