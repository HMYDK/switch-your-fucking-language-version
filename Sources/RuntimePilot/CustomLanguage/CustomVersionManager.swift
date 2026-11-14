import Combine
import Foundation
import RuntimePilotCore

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

    /// identifier 可以在配置更新时变化，因此每次从当前 config 计算 key
    private var activeVersionKey: String {
        "ActiveVersion_\(config.identifier)"
    }

    init(config: CustomLanguageConfig) {
        self.config = config
        refresh()
    }

    /// 更新配置
    func updateConfig(_ newConfig: CustomLanguageConfig) {
        self.config = newConfig
        refresh()
    }

    /// 刷新版本列表
    func refresh() {
        // 在主线程捕获扫描路径，避免后台扫描期间用户编辑配置造成数据竞争
        let scanPaths = config.expandedScanPaths

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let versions = self.scanVersions(in: scanPaths)

            DispatchQueue.main.async {
                self.installedVersions = versions.sorted {
                    compareVersionDescending($0.version, $1.version)
                }

                // 只恢复用户真正选择过且仍然存在的版本。
                // 不能在首次扫描时把第一个版本伪装成“已激活”：那样既没有生成
                // 环境脚本，也没有持久化，用户会误以为版本已经切换成功。
                let savedPath = UserDefaults.standard.string(forKey: self.activeVersionKey)
                if let savedPath = savedPath,
                    let active = versions.first(where: { $0.path == savedPath }),
                    self.generateEnvScript(for: active)
                {
                    // 重新生成一次脚本：配置里的 envVarName / pathSuffix 可能刚被编辑过，
                    // 而且这样能保证“Active”状态和环境脚本始终一致。
                    self.activeVersion = active
                } else {
                    self.activeVersion = nil
                }
            }
        }
    }

    /// 设置激活版本并写入环境脚本。
    /// - Returns: false 表示环境变量非法或脚本写入失败，调用方必须把失败反馈给用户。
    @discardableResult
    func setActive(_ version: CustomVersion) -> Bool {
        // 先验证环境变量，避免把一个语法错误的 export 写进用户 shell
        if let rawName = config.envVarName {
            let envVarName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !envVarName.isEmpty {
                guard LanguageConfigValidation.isValidEnvironmentVariableName(envVarName),
                    !LanguageConfigValidation.isReservedEnvironmentVariable(envVarName)
                else {
                    print("Refusing to write env script with invalid variable name: \(envVarName)")
                    return false
                }
            }
        }

        guard generateEnvScript(for: version) else {
            return false
        }

        activeVersion = version
        UserDefaults.standard.set(version.path, forKey: activeVersionKey)
        return true
    }

    // MARK: - Version Scanning

    /// 扫描所有配置路径中的版本
    private func scanVersions(in scanPaths: [String]) -> [CustomVersion] {
        return DirectoryAccessManager.shared.withBestAccess(to: scanPaths) {
        var versions: [CustomVersion] = []
        var seenPaths = Set<String>()

        for scanPath in scanPaths {
            // 处理通配符路径（如 /opt/homebrew/Cellar/node*）
            let expandedPaths = expandWildcardPath(scanPath)

            for path in expandedPaths {
                // Flutter 的安装目录本身就是 SDK 根目录，不是“版本目录的集合”。
                // 如果直接 scanDirectory，会把 bin/dev/examples/packages 当成版本。
                if let flutterVersion = VersionParsing.flutterSDKVersion(at: path) {
                    if !seenPaths.contains(path) {
                        seenPaths.insert(path)
                        versions.append(
                            CustomVersion(
                                version: flutterVersion,
                                source: detectSource(for: path),
                                path: path
                            ))
                    }
                    continue
                }

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

        // 获取通配符模式，并转义正则特殊字符
        let pattern = components[wildcardIndex]
        let escapedPattern = pattern
            .split(separator: "*", omittingEmptySubsequences: false)
            .map { NSRegularExpression.escapedPattern(for: String($0)) }
            .joined(separator: ".*")
        let regexPattern = "^" + escapedPattern + "$"
        let regex = try? NSRegularExpression(pattern: regexPattern, options: [])
        let isCellarPath = BrewScanner.cellarRoots.contains(basePath)

        // 扫描基础目录
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: basePath)

            for item in contents {
                if item.hasPrefix(".") { continue }

                let matched: Bool
                if isCellarPath, pattern.hasSuffix("*") {
                    matched = VersionParsing.matchesBrewFormula(item, pattern: pattern)
                } else if let regex = regex {
                    matched =
                        regex.firstMatch(
                            in: item, range: NSRange(item.startIndex..., in: item)) != nil
                } else {
                    matched = false
                }

                guard matched else { continue }

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

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)

            for item in contents {
                // 跳过隐藏文件
                if item.hasPrefix(".") { continue }

                let itemPath = (path as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false

                if fileManager.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue {
                    let source = detectSource(for: path, formulaName: item)
                    // 获取实际的可用路径（处理特殊目录结构）
                    let actualPath = findActualPath(for: itemPath)

                    // rustup toolchain 的 stable/beta/nightly 目录名没有数字，
                    // 不能交给 extractVersion，否则会被丢弃。
                    if VersionParsing.isRustToolchainDirectory(path) {
                        let version = VersionParsing.extractVersion(from: item) ?? item
                        versions.append(
                            CustomVersion(
                                version: version,
                                source: source,
                                path: actualPath
                            ))
                        continue
                    }

                    // 尝试从目录名提取版本号
                    if let version = VersionParsing.extractVersion(from: item) {
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

        // Go: 检查 libexec 结构（Homebrew）
        let goLibexec = (basePath as NSString).appendingPathComponent("libexec")
        let goLibexecBin = (goLibexec as NSString).appendingPathComponent("bin/go")
        if fileManager.fileExists(atPath: goLibexecBin) {
            return goLibexec
        }

        // Go: asdf 的布局是 <install>/go/bin/go，GOROOT 需要指向 <install>/go
        let goNested = (basePath as NSString).appendingPathComponent("go")
        let goNestedBin = (goNested as NSString).appendingPathComponent("bin/go")
        if fileManager.fileExists(atPath: goNestedBin) {
            return goNested
        }

        // 默认返回原始路径
        return basePath
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

    /// 生成环境配置脚本。
    /// - Returns: 是否成功写入。即使没有配置 envVarName，也会生成只更新 PATH 的脚本。
    private func generateEnvScript(for version: CustomVersion) -> Bool {
        let fileManager = FileManager.default
        let configDir = RuntimePilotPaths.environmentConfigDirectory

        // 防止 configFileName 或 identifier 中的 ../、/ 把脚本写到配置目录之外
        let baseURL = configDir.standardizedFileURL
        let scriptURL = configDir.appendingPathComponent(config.generatedConfigFileName)
            .standardizedFileURL
        guard scriptURL.path.hasPrefix(baseURL.path + "/") else {
            print("Refusing to write env script outside config directory: \(scriptURL.path)")
            return false
        }

        let envVarName = (config.envVarName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !envVarName.isEmpty {
            guard LanguageConfigValidation.isValidEnvironmentVariableName(envVarName),
                !LanguageConfigValidation.isReservedEnvironmentVariable(envVarName)
            else {
                print("Refusing to write env script with invalid variable name: \(envVarName)")
                return false
            }
        }

        let runtimePath = environmentRoot(for: version)
        let scriptContent = EnvironmentScript.content(
            languageName: config.name,
            version: version.version,
            runtimePath: runtimePath,
            environmentVariableName: envVarName.isEmpty ? nil : envVarName,
            pathSuffix: config.effectivePathSuffix
        )

        do {
            try fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
            try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Failed to write env script: \(error)")
            return false
        }
    }

    /// 版本在环境变量中实际应指向的运行时根目录。
    /// 目前 .NET SDK 的扫描路径是 <dotnetRoot>/sdk/<version>，而 DOTNET_ROOT 需要的是 <dotnetRoot>。
    private func environmentRoot(for version: CustomVersion) -> String {
        if config.envVarName?.uppercased() == "DOTNET_ROOT" {
            return RuntimePathResolution.dotnetRoot(fromVersionPath: version.path)
        }
        return version.path
    }

}
