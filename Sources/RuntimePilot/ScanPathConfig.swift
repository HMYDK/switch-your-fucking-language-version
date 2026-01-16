import Foundation

// MARK: - Path Source

/// 扫描路径来源类型
enum PathSource: String, Codable, CaseIterable {
    case homebrew = "homebrew"
    case pyenv = "pyenv"
    case nvm = "nvm"
    case gvm = "gvm"
    case asdf = "asdf"
    case rbenv = "rbenv"
    case rvm = "rvm"
    case rustup = "rustup"
    case javaHome = "java_home"
    case system = "system"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .homebrew: return "Homebrew"
        case .pyenv: return "pyenv"
        case .nvm: return "nvm"
        case .gvm: return "gvm"
        case .asdf: return "asdf"
        case .rbenv: return "rbenv"
        case .rvm: return "rvm"
        case .rustup: return "rustup"
        case .javaHome: return "System JDK"
        case .system: return "System"
        case .custom: return "Custom"
        }
    }

    /// 从路径推断来源类型
    static func detect(from path: String) -> PathSource {
        let lowercasePath = path.lowercased()

        if lowercasePath.contains("homebrew") || lowercasePath.contains("cellar") {
            return .homebrew
        } else if lowercasePath.contains("pyenv") {
            return .pyenv
        } else if lowercasePath.contains("nvm") {
            return .nvm
        } else if lowercasePath.contains("gvm") {
            return .gvm
        } else if lowercasePath.contains("asdf") {
            return .asdf
        } else if lowercasePath.contains("rbenv") {
            return .rbenv
        } else if lowercasePath.contains("rvm") {
            return .rvm
        } else if lowercasePath.contains("rustup") {
            return .rustup
        } else if lowercasePath.contains("/library/java/javavirtualmachines") {
            return .javaHome
        } else {
            return .custom
        }
    }
}

// MARK: - Scan Path Info

/// 单个扫描路径的完整信息
struct ScanPathInfo: Identifiable, Equatable {
    let id: UUID
    let path: String
    let source: PathSource
    let displayName: String
    let isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        path: String,
        source: PathSource? = nil,
        displayName: String? = nil,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.path = path
        self.source = source ?? PathSource.detect(from: path)
        self.displayName = displayName ?? self.source.displayName
        self.isBuiltIn = isBuiltIn
    }

    /// 展开 ~ 后的完整路径
    var expandedPath: String {
        if path.hasPrefix("~") {
            return (path as NSString).expandingTildeInPath
        }
        return path
    }

    /// 检查路径是否存在（支持通配符路径）
    var exists: Bool {
        let expanded = expandedPath
        if expanded.contains("*") {
            // 对于通配符路径，委托给 ScanPathConfigManager 处理
            return ScanPathConfigManager.shared.checkPathStatus(path).exists
        }
        return FileManager.default.fileExists(atPath: expanded)
    }

    static func == (lhs: ScanPathInfo, rhs: ScanPathInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Path Status

/// 路径状态信息
struct PathStatus {
    let exists: Bool
    let isAccessible: Bool
    let versionCount: Int?

    static let unknown = PathStatus(exists: false, isAccessible: false, versionCount: nil)
}
