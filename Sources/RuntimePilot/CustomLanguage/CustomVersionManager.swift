import Combine
import Foundation

// MARK: - Custom Version

/// 自定义语言版本
struct CustomVersion: LanguageVersion, Identifiable {
    let id: UUID
    let version: String
    let source: String
    let path: String

    init(id: UUID = UUID(), version: String, source: String, path: String) {
        self.id = id
        self.version = version
        self.source = source
        self.path = path
    }
}

// MARK: - Custom Version Manager

/// 自定义语言版本管理器 - 实现 LanguageManager 协议
final class CustomVersionManager: ObservableObject, LanguageManager {
    typealias Version = CustomVersion

    @Published private(set) var installedVersions: [CustomVersion] = []
    @Published private(set) var activeVersion: CustomVersion?

    private var config: CustomLanguageConfig
    private let activeVersionKey: String

    init(config: CustomLanguageConfig) {
        self.config = config
        self.activeVersionKey = "ActiveVersion_\(config.identifier)"
        refresh()
    }

    /// 更新配置
    func updateConfig(_ newConfig: CustomLanguageConfig) {
        self.config = newConfig
        refresh()
    }

    /// 刷新版本列表
    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let versions = self.scanVersions()
            let savedActiveVersion = UserDefaults.standard.string(forKey: self.activeVersionKey)

            DispatchQueue.main.async {
                self.installedVersions = versions.sorted {
                    compareVersionDescending($0.version, $1.version)
                }

                // 恢复激活的版本
                if let savedPath = savedActiveVersion,
                    let active = versions.first(where: { $0.path == savedPath })
                {
                    self.activeVersion = active
                } else if let first = self.installedVersions.first {
                    // 默认使用第一个版本
                    self.activeVersion = first
                }
            }
        }
    }

    /// 设置激活版本
    func setActive(_ version: CustomVersion) {
        activeVersion = version
        UserDefaults.standard.set(version.path, forKey: activeVersionKey)

        // 生成环境配置脚本
        generateEnvScript(for: version)
    }

    // MARK: - Version Scanning

    /// 扫描所有配置路径中的版本
    private func scanVersions() -> [CustomVersion] {
        var versions: [CustomVersion] = []
        var seenPaths = Set<String>()

        for scanPath in config.expandedScanPaths {
            // 处理通配符路径（如 /opt/homebrew/Cellar/node*）
            let expandedPaths = expandWildcardPath(scanPath)

            for path in expandedPaths {
                let scannedVersions = scanDirectory(at: path)
                for version in scannedVersions {
                    // 避免重复
                    if !seenPaths.contains(version.path) {
                        seenPaths.insert(version.path)
                        versions.append(version)
                    }
                }
            }
        }

        return versions
    }

    /// 展开通配符路径
    private func expandWildcardPath(_ path: String) -> [String] {
        // 如果路径不包含通配符，直接返回
        guard path.contains("*") else {
            return [path]
        }

        let fileManager = FileManager.default
        var results: [String] = []

        // 找到通配符前的基础路径
        let components = path.components(separatedBy: "/")
        var basePath = ""
        var wildcardIndex = -1

        for (index, component) in components.enumerated() {
            if component.contains("*") {
                wildcardIndex = index
                break
            }
            if !component.isEmpty {
                basePath += "/" + component
            }
        }

        guard wildcardIndex >= 0, !basePath.isEmpty else {
            return [path]
        }

        // 获取通配符模式
        let pattern = components[wildcardIndex]
        let regexPattern = "^" + pattern.replacingOccurrences(of: "*", with: ".*") + "$"

        // 扫描基础目录
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: basePath)

            for item in contents {
                if item.hasPrefix(".") { continue }

                // 检查是否匹配通配符模式
                if let regex = try? NSRegularExpression(pattern: regexPattern, options: []),
                    regex.firstMatch(in: item, range: NSRange(item.startIndex..., in: item)) != nil
                {
                    let matchedPath = (basePath as NSString).appendingPathComponent(item)

                    // 如果通配符后还有更多路径组件，递归处理
                    if wildcardIndex + 1 < components.count {
                        let remainingPath = components[(wildcardIndex + 1)...].joined(
                            separator: "/")
                        let fullPath = (matchedPath as NSString).appendingPathComponent(
                            remainingPath)
                        results.append(contentsOf: expandWildcardPath(fullPath))
                    } else {
                        results.append(matchedPath)
                    }
                }
            }
        } catch {
            // 目录不存在或无法访问
        }

        return results.isEmpty ? [] : results
    }

    /// 扫描单个目录
    private func scanDirectory(at path: String) -> [CustomVersion] {
        let fileManager = FileManager.default
        var versions: [CustomVersion] = []

        // 检查目录是否存在
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            return []
        }

        // 尝试使用 Security-Scoped Bookmark 访问
        let url = URL(fileURLWithPath: path)
        let accessGranted = DirectoryAccessManager.shared.startAccessing(url: url)
        defer {
            if accessGranted {
                DirectoryAccessManager.shared.stopAccessing(url: url)
            }
        }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)

            for item in contents {
                // 跳过隐藏文件
                if item.hasPrefix(".") { continue }

                let itemPath = (path as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false

                if fileManager.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue {
                    // 尝试从目录名提取版本号
                    if let version = extractVersion(from: item) {
                        let source = detectSource(for: path, formulaName: item)

                        // 获取实际的可用路径（处理特殊目录结构）
                        let actualPath = findActualPath(for: itemPath)

                        versions.append(
                            CustomVersion(
                                version: version,
                                source: source,
                                path: actualPath
                            ))
                    }
                }
            }
        } catch {
            print("Failed to scan directory \(path): \(error)")
        }

        return versions
    }

    /// 查找实际可用的路径（处理特殊目录结构）
    private func findActualPath(for basePath: String) -> String {
        let fileManager = FileManager.default

        // Java JDK: 检查 Contents/Home 结构
        let jdkContentsHome = (basePath as NSString).appendingPathComponent("Contents/Home")
        if fileManager.fileExists(atPath: jdkContentsHome) {
            return jdkContentsHome
        }

        // Homebrew OpenJDK: 检查 libexec/openjdk.jdk/Contents/Home 结构
        let homebrewJdkPath = (basePath as NSString).appendingPathComponent(
            "libexec/openjdk.jdk/Contents/Home")
        if fileManager.fileExists(atPath: homebrewJdkPath) {
            return homebrewJdkPath
        }

        // Go: 检查 libexec 结构
        let goLibexec = (basePath as NSString).appendingPathComponent("libexec")
        let goLibexecBin = (goLibexec as NSString).appendingPathComponent("bin/go")
        if fileManager.fileExists(atPath: goLibexecBin) {
            return goLibexec
        }

        // 默认返回原始路径
        return basePath
    }

    /// 从目录名提取版本号
    private func extractVersion(from directoryName: String) -> String? {
        // 常见的版本目录命名模式
        // 例如: "3.12.0", "ruby-3.2.0", "v18.0.0", "go1.21.0"

        let patterns = [
            // 纯版本号: 3.12.0, 18.0.0
            "^(\\d+\\.\\d+(?:\\.\\d+)?)$",
            // 带前缀: ruby-3.2.0, python-3.12.0
            "^[a-zA-Z]+-?(\\d+\\.\\d+(?:\\.\\d+)?)$",
            // v前缀: v18.0.0
            "^v(\\d+\\.\\d+(?:\\.\\d+)?)$",
            // go风格: go1.21.0
            "^[a-zA-Z]+(\\d+\\.\\d+(?:\\.\\d+)?)$",
            // 任意带版本的: xxx-3.2.0-xxx
            "(\\d+\\.\\d+(?:\\.\\d+)?)",
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                let match = regex.firstMatch(
                    in: directoryName,
                    range: NSRange(directoryName.startIndex..., in: directoryName))
            {
                if let range = Range(match.range(at: 1), in: directoryName) {
                    return String(directoryName[range])
                }
            }
        }

        // 如果没有匹配，直接返回目录名作为版本
        return directoryName
    }

    /// 检测版本来源
    private func detectSource(for path: String, formulaName: String? = nil) -> String {
        let lowercasePath = path.lowercased()

        if lowercasePath.contains("homebrew") || lowercasePath.contains("cellar") {
            // 检测 Homebrew formula 名称（如 node@18, python@3.13）
            if let name = formulaName, name.contains("@") {
                return "Homebrew (\(name))"
            }
            return "Homebrew"
        } else if lowercasePath.contains("/library/java/javavirtualmachines") {
            return "System JDK"
        } else if lowercasePath.contains("rbenv") {
            return "rbenv"
        } else if lowercasePath.contains("rvm") {
            return "RVM"
        } else if lowercasePath.contains("pyenv") {
            return "pyenv"
        } else if lowercasePath.contains("rustup") {
            return "rustup"
        } else if lowercasePath.contains("nvm") {
            return "NVM"
        } else if lowercasePath.contains("asdf") {
            return "asdf"
        } else if lowercasePath.contains("gvm") {
            return "GVM"
        } else {
            return "Local"
        }
    }

    // MARK: - Environment Script

    /// 生成环境配置脚本
    private func generateEnvScript(for version: CustomVersion) {
        guard let envVarName = config.envVarName, !envVarName.isEmpty else {
            return
        }

        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("runtimepilot")

        // 创建目录
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        let scriptPath = configDir.appendingPathComponent(config.generatedConfigFileName)

        let scriptContent = """
            # \(config.name) Environment Configuration
            # Generated by RuntimePilot
            # Active version: \(version.version)

            export \(envVarName)="\(version.path)"
            export PATH="$\(envVarName)/bin:$PATH"
            """

        do {
            try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write env script: \(error)")
        }
    }
}
