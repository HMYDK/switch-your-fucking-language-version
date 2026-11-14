import Foundation

/// 将扫描到的版本路径转换为运行时根目录。
public enum RuntimePathResolution {

    /// .NET SDK 的扫描路径通常是 <dotnetRoot>/sdk/<version>，
    /// 而 DOTNET_ROOT 应指向包含 dotnet 可执行文件的 <dotnetRoot>。
    public static func dotnetRoot(
        fromVersionPath path: String,
        fileManager: FileManager = .default
    ) -> String {
        let sdkURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        guard sdkURL.lastPathComponent == "sdk" else {
            return path
        }
        let rootURL = sdkURL.deletingLastPathComponent()
        let dotnetPath = rootURL.appendingPathComponent("dotnet").path
        return fileManager.fileExists(atPath: dotnetPath) ? rootURL.path : path
    }
}
