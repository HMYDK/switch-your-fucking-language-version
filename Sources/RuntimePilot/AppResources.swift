import Foundation

/// 资源查找：
/// 1. 打包后的 App 从 Bundle.main（Contents/Resources）读取 PNG；
/// 2. swift run 等开发环境从 SwiftPM 资源 bundle 读取。
///
/// 不使用 Bundle.module：它会在资源 bundle 缺失时直接 fatalError，
/// 也不适合放在 .app 根目录（会阻止 bundle 被 codesign 正常签名）。
enum AppResources {
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }

        let bundleName = "RuntimePilot_RuntimePilot"
        let candidates: [URL?] = [
            Bundle.main.bundleURL.appendingPathComponent("\(bundleName).bundle"),
            Bundle.main.resourceURL?.appendingPathComponent("\(bundleName).bundle"),
            Bundle.main.bundleURL.deletingLastPathComponent()
                .appendingPathComponent("\(bundleName).bundle"),
        ]

        for candidate in candidates.compactMap({ $0 }) {
            guard let bundle = Bundle(url: candidate),
                let url = bundle.url(forResource: name, withExtension: ext)
            else {
                continue
            }
            return url
        }
        return nil
    }
}
