import Foundation

/// 版本目录名解析与路径匹配规则。
/// 这些规则不依赖 UI，独立放在 core 模块中以便自动化测试。
public enum VersionParsing {

    /// 从目录名提取版本号。
    /// 支持 "3.12.0"、"v18.0.0"、"ruby-3.2.0"、"go1.21.0"、"temurin-17.jdk" 等形式。
    /// 没有版本信息时返回 nil，不再把任意目录名当成版本。
    public static func extractVersion(from directoryName: String) -> String? {
        let patterns = [
            // 纯版本号: 3.12.0, 18.0.0
            "^(\\d+(?:\\.\\d+)+)$",
            // 带前缀: ruby-3.2.0, python-3.12.0
            "^[a-zA-Z]+-?(\\d+(?:\\.\\d+)+)$",
            // v前缀: v18.0.0
            "^v(\\d+(?:\\.\\d+)+)$",
            // go风格: go1.21.0
            "^[a-zA-Z]+(\\d+(?:\\.\\d+)+)$",
            // JDK 单数字版本: temurin-17.jdk, jdk-17
            "^[a-zA-Z][a-zA-Z0-9_-]*-v?(\\d+(?:\\.\\d+)*)(?:\\.jdk)?$",
            // 任意带版本的: xxx-3.2.0-xxx
            "(\\d+(?:\\.\\d+)+)",
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

        return nil
    }

    /// 判断目录是否是 rustup toolchain 目录（这类目录名需要原样保留）
    public static func isRustToolchainDirectory(_ path: String) -> Bool {
        let normalized = path.lowercased().replacingOccurrences(of: "\\", with: "/")
        return normalized.contains("/.rustup/toolchains")
            || normalized.hasSuffix(".rustup/toolchains")
    }

    /// 如果目录本身是一个 Flutter SDK，返回其版本号；否则返回 nil。
    public static func flutterSDKVersion(at path: String, fileManager: FileManager = .default)
        -> String?
    {
        let flutterBinary = (path as NSString).appendingPathComponent("bin/flutter")
        guard fileManager.fileExists(atPath: flutterBinary) else {
            return nil
        }

        let versionPath = (path as NSString).appendingPathComponent("version")
        if let data = fileManager.contents(atPath: versionPath),
            let text = String(data: data, encoding: .utf8)
        {
            let version = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !version.isEmpty {
                return version
            }
        }
        return "SDK"
    }

    /// Homebrew Cellar 通配符语义：
    /// - go* 匹配 go、go@1.22，不匹配 golangci-lint
    /// - python@* 匹配 python@3.13
    public static func matchesBrewFormula(_ item: String, pattern: String) -> Bool {
        guard pattern.hasSuffix("*") else {
            return false
        }
        let prefix = String(pattern.dropLast())
        if prefix.hasSuffix("@") {
            return item.hasPrefix(prefix)
        }
        return item == prefix || item.hasPrefix(prefix + "@")
    }
}
