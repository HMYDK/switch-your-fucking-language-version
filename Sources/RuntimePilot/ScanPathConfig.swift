import Foundation

// MARK: - Path Source

/// 扫描路径来源类型
enum PathSource: String, Codable, CaseIterable {
    case homebrew = "homebrew"
    case pyenv = "pyenv"
    case nvm = "nvm"
    case gvm = "gvm"
    case asdf = "asdf"
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
        case .javaHome: return "Java Home"
        case .system: return "System"
        case .custom: return "Custom"
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
        source: PathSource,
        displayName: String? = nil,
        isBuiltIn: Bool = true
    ) {
        self.id = id
        self.path = path
        self.source = source
        self.displayName = displayName ?? source.displayName
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

// MARK: - Built-in Paths Definition

/// 内置语言的默认扫描路径定义
enum BuiltInScanPaths {
    static let python: [ScanPathInfo] = [
        ScanPathInfo(
            path: "/opt/homebrew/Cellar/python*",
            source: .homebrew,
            displayName: "Homebrew (Apple Silicon)"
        ),
        ScanPathInfo(
            path: "/usr/local/Cellar/python*",
            source: .homebrew,
            displayName: "Homebrew (Intel)"
        ),
        ScanPathInfo(
            path: "~/.pyenv/versions",
            source: .pyenv
        ),
        ScanPathInfo(
            path: "~/.asdf/installs/python",
            source: .asdf
        ),
    ]

    static let go: [ScanPathInfo] = [
        ScanPathInfo(
            path: "/opt/homebrew/Cellar/go*",
            source: .homebrew,
            displayName: "Homebrew (Apple Silicon)"
        ),
        ScanPathInfo(
            path: "/usr/local/Cellar/go*",
            source: .homebrew,
            displayName: "Homebrew (Intel)"
        ),
        ScanPathInfo(
            path: "~/.gvm/gos",
            source: .gvm
        ),
        ScanPathInfo(
            path: "~/.asdf/installs/golang",
            source: .asdf
        ),
    ]

    static let node: [ScanPathInfo] = [
        ScanPathInfo(
            path: "/opt/homebrew/Cellar/node*",
            source: .homebrew,
            displayName: "Homebrew (Apple Silicon)"
        ),
        ScanPathInfo(
            path: "/usr/local/Cellar/node*",
            source: .homebrew,
            displayName: "Homebrew (Intel)"
        ),
        ScanPathInfo(
            path: "~/.nvm/versions/node",
            source: .nvm
        ),
    ]

    static let java: [ScanPathInfo] = [
        ScanPathInfo(
            path: "/Library/Java/JavaVirtualMachines",
            source: .javaHome,
            displayName: "System JDK"
        ),
        ScanPathInfo(
            path: "/opt/homebrew/Cellar/openjdk*",
            source: .homebrew,
            displayName: "Homebrew (Apple Silicon)"
        ),
        ScanPathInfo(
            path: "/usr/local/Cellar/openjdk*",
            source: .homebrew,
            displayName: "Homebrew (Intel)"
        ),
    ]

    /// 获取指定语言的内置路径
    static func paths(for languageId: String) -> [ScanPathInfo] {
        switch languageId {
        case "python": return python
        case "go": return go
        case "node": return node
        case "java": return java
        default: return []
        }
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
