import Combine
import Foundation

struct JavaVersion: LanguageVersion, Hashable {
    let id = UUID()
    let homePath: String
    let name: String
    let version: String

    // LanguageVersion 协议要求
    var path: String { homePath }
    var source: String { name }
}

class JavaManager: ObservableObject, LanguageManager {
    typealias Version = JavaVersion
    @Published var installedVersions: [JavaVersion] = []
    @Published var activeVersion: JavaVersion?

    private let configDir: URL
    private let envFile: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configDir = home.appendingPathComponent(".config/devmanager")
        envFile = configDir.appendingPathComponent("java_env.sh")

        refresh()
    }

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            var versions = self.fetchFromJavaHome()
            let brewVersions = self.fetchFromHomebrew()

            // 合并，避免重复
            for brewVersion in brewVersions {
                if !versions.contains(where: { $0.homePath == brewVersion.homePath }) {
                    versions.append(brewVersion)
                }
            }

            // Custom scan paths
            let customVersions = self.fetchFromCustomPaths()
            for customVersion in customVersions {
                if !versions.contains(where: { $0.homePath == customVersion.homePath }) {
                    versions.append(customVersion)
                }
            }

            DispatchQueue.main.async {
                self.installedVersions = versions
                self.checkActiveVersion()
            }
        }
    }

    private func fetchFromJavaHome() -> [JavaVersion] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")
        task.arguments = ["-X"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            // Parse Plist
            if let plist = try PropertyListSerialization.propertyList(
                from: data, options: [], format: nil) as? [[String: Any]]
            {
                return plist.compactMap { dict -> JavaVersion? in
                    guard let home = dict["JVMHomePath"] as? String,
                        let name = dict["JVMName"] as? String,
                        let version = dict["JVMVersion"] as? String
                    else {
                        return nil
                    }
                    return JavaVersion(homePath: home, name: name, version: version)
                }
            }
        } catch {
            print("Error finding java versions via java_home: \(error)")
        }
        return []
    }

    private func fetchFromHomebrew() -> [JavaVersion] {
        // 使用公共扫描工具
        return BrewScanner.scanJava().map { brew in
            JavaVersion(homePath: brew.homePath, name: brew.name, version: brew.version)
        }
    }

    private func fetchFromCustomPaths() -> [JavaVersion] {
        var versions: [JavaVersion] = []
        let fileManager = FileManager.default

        for customPath in ScanPathConfigManager.shared.getCustomPaths(for: "java") {
            let expandedPath = (customPath as NSString).expandingTildeInPath

            // Check if the path itself is a valid JDK home
            if isValidJdkHome(expandedPath) {
                if let version = readJdkVersion(from: expandedPath) {
                    let name = (expandedPath as NSString).lastPathComponent
                    versions.append(
                        JavaVersion(
                            homePath: expandedPath, name: "Custom: \(name)", version: version))
                }
                continue
            }

            // Otherwise, scan subdirectories
            if let items = try? fileManager.contentsOfDirectory(atPath: expandedPath) {
                for item in items {
                    if item.hasPrefix(".") { continue }
                    let fullPath = (expandedPath as NSString).appendingPathComponent(item)

                    // Check for JDK structure: Contents/Home or direct bin/java
                    var jdkHome = fullPath
                    let contentsHome = (fullPath as NSString).appendingPathComponent(
                        "Contents/Home")
                    if fileManager.fileExists(atPath: contentsHome) {
                        jdkHome = contentsHome
                    }

                    if isValidJdkHome(jdkHome) {
                        if let version = readJdkVersion(from: jdkHome) {
                            versions.append(
                                JavaVersion(
                                    homePath: jdkHome, name: "Custom: \(item)", version: version))
                        }
                    }
                }
            }
        }

        return versions
    }

    private func isValidJdkHome(_ path: String) -> Bool {
        let fileManager = FileManager.default
        let javaBin = (path as NSString).appendingPathComponent("bin/java")
        return fileManager.fileExists(atPath: javaBin)
    }

    private func readJdkVersion(from jdkHome: String) -> String? {
        let releasePath = (jdkHome as NSString).appendingPathComponent("release")
        guard let content = try? String(contentsOfFile: releasePath, encoding: .utf8) else {
            // Fallback: use directory name as version
            return (jdkHome as NSString).lastPathComponent
        }

        // Parse JAVA_VERSION from release file
        for line in content.components(separatedBy: .newlines) {
            if line.hasPrefix("JAVA_VERSION=") {
                var version = line.replacingOccurrences(of: "JAVA_VERSION=", with: "")
                version = version.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                return version
            }
        }

        return (jdkHome as NSString).lastPathComponent
    }

    private func checkActiveVersion() {
        if FileManager.default.fileExists(atPath: envFile.path) {
            do {
                let content = try String(contentsOf: envFile)
                if let range = content.range(of: "export JAVA_HOME=\"") {
                    let suffix = content[range.upperBound...]
                    if let endRange = suffix.range(of: "\"") {
                        let path = String(suffix[..<endRange.lowerBound])
                        DispatchQueue.main.async {
                            self.activeVersion = self.installedVersions.first {
                                $0.homePath == path
                            }
                        }
                        return
                    }
                }
            } catch {
                print("Error reading selected version from config: \(error)")
            }
        }

        DispatchQueue.main.async {
            self.activeVersion = nil
        }
    }

    func setActive(_ version: JavaVersion) {
        do {
            if !FileManager.default.fileExists(atPath: configDir.path) {
                try FileManager.default.createDirectory(
                    at: configDir, withIntermediateDirectories: true)
            }

            let content =
                "export JAVA_HOME=\"\(version.homePath)\"\nexport PATH=\"$JAVA_HOME/bin:$PATH\"\n"
            try content.write(to: envFile, atomically: true, encoding: .utf8)

            DispatchQueue.main.async {
                self.activeVersion = version
            }
        } catch {
            print("Error setting active version: \(error)")
        }
    }
}
