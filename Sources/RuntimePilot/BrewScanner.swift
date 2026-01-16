import Foundation

/// Homebrew 扫描到的版本信息
struct BrewInstalledVersion {
    let formulaName: String  // e.g., "node", "node@18", "python@3.13"
    let version: String  // e.g., "24.9.0", "3.13.11"
    let cellarPath: String  // e.g., "/opt/homebrew/Cellar/node/24.9.0"

    /// 清理后的版本号（去掉 _1 等修订后缀）
    var cleanVersion: String {
        version.components(separatedBy: "_").first ?? version
    }

    /// 显示用的来源名称
    var sourceDisplay: String {
        if formulaName.contains("@") {
            return "Homebrew (\(formulaName))"
        }
        return "Homebrew"
    }
}

/// Homebrew Cellar 目录扫描工具
enum BrewScanner {

    /// Homebrew Cellar 根目录（支持 Apple Silicon 和 Intel Mac）
    static let cellarRoots = ["/opt/homebrew/Cellar", "/usr/local/Cellar"]

    // MARK: - 通用扫描

    /// 扫描指定前缀的 Homebrew formula
    /// - Parameters:
    ///   - prefix: formula 名称前缀，如 "node", "python@", "openjdk"
    ///   - exactMatch: 是否精确匹配（仅匹配 prefix 本身）
    /// - Returns: 找到的版本列表
    static func scanFormulae(prefix: String, exactMatch: Bool = false) -> [BrewInstalledVersion] {
        var results: [BrewInstalledVersion] = []
        let fileManager = FileManager.default

        for root in cellarRoots {
            guard let items = try? fileManager.contentsOfDirectory(atPath: root) else { continue }

            for item in items {
                let matches: Bool
                if exactMatch {
                    matches = item == prefix
                } else {
                    matches = item == prefix || item.hasPrefix("\(prefix)@")
                }

                guard matches else { continue }

                let formulaPath = (root as NSString).appendingPathComponent(item)
                guard let versionDirs = try? fileManager.contentsOfDirectory(atPath: formulaPath)
                else { continue }

                for versionDir in versionDirs {
                    // 跳过隐藏文件和符号链接
                    if versionDir.hasPrefix(".") { continue }

                    let versionPath = (formulaPath as NSString).appendingPathComponent(versionDir)
                    var isDirectory: ObjCBool = false

                    if fileManager.fileExists(atPath: versionPath, isDirectory: &isDirectory),
                        isDirectory.boolValue
                    {
                        results.append(
                            BrewInstalledVersion(
                                formulaName: item,
                                version: versionDir,
                                cellarPath: versionPath
                            ))
                    }
                }
            }
        }

        return results
    }
}
