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

        for scanPath in config.expandedScanPaths {
            let scannedVersions = scanDirectory(at: scanPath)
            versions.append(contentsOf: scannedVersions)
        }

        return versions
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
                        let source = detectSource(for: path)
                        versions.append(
                            CustomVersion(
                                version: version,
                                source: source,
                                path: itemPath
                            ))
                    }
                }
            }
        } catch {
            print("Failed to scan directory \(path): \(error)")
        }

        return versions
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
    private func detectSource(for path: String) -> String {
        let lowercasePath = path.lowercased()

        if lowercasePath.contains("homebrew") || lowercasePath.contains("cellar") {
            return "Homebrew"
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
            .appendingPathComponent("devmanager")

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
