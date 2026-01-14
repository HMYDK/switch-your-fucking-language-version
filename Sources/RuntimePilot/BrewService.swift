import Foundation

/// Homebrew 服务 - 检测 Homebrew 安装状态和版本来源
/// App Store 版本仅提供只读检测功能，不执行安装/卸载操作
class BrewService {
    static let shared = BrewService()

    private let brewPath: String?

    private init() {
        brewPath = Self.resolveBrewPath()
    }

    /// 检查 Homebrew 是否可用
    var isAvailable: Bool {
        brewPath != nil
    }

    // MARK: - 版本来源识别

    /// 获取通过路径推断的 formula 名称
    func getFormulaName(from path: String) -> String? {
        // 从路径中提取 formula 名称
        // 例如: /opt/homebrew/Cellar/node@20/20.x.x -> node@20
        //      /opt/homebrew/Cellar/openjdk@17/17.x.x -> openjdk@17
        if path.contains("/Cellar/") {
            let components = path.components(separatedBy: "/Cellar/")
            if components.count > 1 {
                let formulaPath = components[1]
                let formulaName = formulaPath.components(separatedBy: "/").first
                return formulaName
            }
        }
        return nil
    }

    /// 判断指定路径是否为 Homebrew 安装
    func isHomebrewInstalled(path: String) -> Bool {
        return path.contains("/opt/homebrew/") || path.contains("/usr/local/Cellar/")
    }

    // MARK: - 私有方法

    private static func resolveBrewPath() -> String? {
        let fileManager = FileManager.default

        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
        ]

        for path in candidates where fileManager.fileExists(atPath: path) {
            return path
        }

        // 如果常见路径都不存在，尝试通过 which 命令查找
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["brew"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()

            guard task.terminationStatus == 0,
                let output = String(data: data, encoding: .utf8)
            else {
                return nil
            }

            let resolved = output.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !resolved.isEmpty, fileManager.fileExists(atPath: resolved) else { return nil }
            return resolved
        } catch {
            return nil
        }
    }
}
