import Darwin
import Foundation
import RuntimePilotCore

// A tiny self-contained test runner.
// The checked environment has Command Line Tools but no XCTest/Xcode,
// so this target runs with: swift run RuntimePilotChecks

var testCount = 0
var failures: [String] = []

struct CheckError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

func test(_ name: String, _ body: () throws -> Void) {
    testCount += 1
    do {
        try body()
        print("PASS  \(name)")
    } catch {
        failures.append("\(name): \(error)")
        print("FAIL  \(name): \(error)")
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckError(message: message)
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "values differ")
    throws
{
    if actual != expected {
        throw CheckError(message: "\(message): expected \(expected), got \(actual)")
    }
}

func expectNil<T>(_ value: T?, _ message: String = "expected nil") throws {
    if value != nil {
        throw CheckError(message: "\(message), got \(String(describing: value))")
    }
}

func makeTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("RuntimePilotChecks-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

// MARK: - Version sorting

func testVersionSorting() throws {
    try expect(compareVersionDescending("1.10.0", "1.9.0"), "1.10 should be newer than 1.9")
    try expect(!compareVersionDescending("1.9.0", "1.10.0"), "1.9 should not be newer")
    try expect(compareVersionDescending("24.14.0", "22.23.2"), "numeric ordering")
    try expect(!compareVersionDescending("1.0.0", "1.0.0"), "equal versions are not descending")
}

// MARK: - Version extraction

func testVersionExtraction() throws {
    let cases: [(String, String?)] = [
        ("3.12.0", "3.12.0"),
        ("v24.14.0", "24.14.0"),
        ("ruby-3.2.0", "3.2.0"),
        ("go1.21.0", "1.21.0"),
        ("temurin-17.jdk", "17"),
        ("jdk-21.0.1", "21.0.1"),
        ("1.95.0-aarch64-apple-darwin", "1.95.0"),
        ("bin", nil),
        ("dev", nil),
        ("packages", nil),
        ("stable-aarch64-apple-darwin", nil),
    ]
    for (input, expected) in cases {
        try expectEqual(
            VersionParsing.extractVersion(from: input), expected, "extractVersion(\(input))")
    }
}

func testRustToolchainDetection() throws {
    try expect(
        VersionParsing.isRustToolchainDirectory("/Users/zk/.rustup/toolchains"),
        "rustup toolchains path")
    try expect(
        VersionParsing.isRustToolchainDirectory("C:\\Users\\zk\\.rustup\\toolchains"),
        "Windows-style rustup path")
    try expect(
        !VersionParsing.isRustToolchainDirectory("/usr/local/Cellar/go/1.21.0"),
        "non-rustup path")
}

func testBrewFormulaMatching() throws {
    try expect(VersionParsing.matchesBrewFormula("go", pattern: "go*"), "go exact")
    try expect(VersionParsing.matchesBrewFormula("go@1.22", pattern: "go*"), "go versioned")
    try expect(
        !VersionParsing.matchesBrewFormula("golangci-lint", pattern: "go*"),
        "must not match golangci-lint")
    try expect(
        VersionParsing.matchesBrewFormula("node@18", pattern: "node*"), "node versioned")
    try expect(
        !VersionParsing.matchesBrewFormula("node-sass", pattern: "node*"),
        "must not match node-sass")
    try expect(
        VersionParsing.matchesBrewFormula("python@3.13", pattern: "python@*"),
        "python@ wildcard")
}

func testFlutterSDKDetection() throws {
    let root = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    let bin = root.appendingPathComponent("bin", isDirectory: true)
    try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: bin.appendingPathComponent("flutter").path, contents: nil)
    try "3.35.1\n".write(
        to: root.appendingPathComponent("version"), atomically: true, encoding: .utf8)

    try expectEqual(VersionParsing.flutterSDKVersion(at: root.path), "3.35.1")

    try FileManager.default.removeItem(at: root.appendingPathComponent("version"))
    try expectEqual(VersionParsing.flutterSDKVersion(at: root.path), "SDK")

    let plain = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: plain) }
    try expectNil(VersionParsing.flutterSDKVersion(at: plain.path))
}

// MARK: - Script generation

func testScriptWithEnvironmentVariable() throws {
    let script = EnvironmentScript.content(
        languageName: "Java",
        version: "17.0.2",
        runtimePath: "/opt/java/17",
        environmentVariableName: "JAVA_HOME",
        pathSuffix: "bin"
    )
    let expected = [
        "# Java Environment Configuration",
        "# Generated by SYFLV",
        "# Active version: 17.0.2",
        "",
        "export JAVA_HOME=\"/opt/java/17\"",
        "export PATH=\"/opt/java/17/bin:$PATH\"",
    ].joined(separator: "\n") + "\n"
    try expectEqual(script, expected)
}

func testScriptWithoutEnvironmentVariable() throws {
    let script = EnvironmentScript.content(
        languageName: "Rust",
        version: "stable-aarch64-apple-darwin",
        runtimePath: "/Users/zk/.rustup/toolchains/stable-aarch64-apple-darwin",
        environmentVariableName: nil,
        pathSuffix: "bin"
    )
    try expect(!script.contains("RUSTUP_HOME"), "Rust script must not set RUSTUP_HOME")
    try expect(
        script.contains(
            "export PATH=\"/Users/zk/.rustup/toolchains/stable-aarch64-apple-darwin/bin:$PATH\""),
        "Rust PATH entry")
}

func testScriptWithRootPathSuffix() throws {
    let script = EnvironmentScript.content(
        languageName: ".NET",
        version: "9.0.100",
        runtimePath: "/usr/local/share/dotnet",
        environmentVariableName: "DOTNET_ROOT",
        pathSuffix: ""
    )
    try expect(
        script.contains("export DOTNET_ROOT=\"/usr/local/share/dotnet\""),
        "DOTNET_ROOT entry")
    try expect(
        script.contains("export PATH=\"/usr/local/share/dotnet:$PATH\""),
        "dotnet PATH entry")
    try expect(!script.contains("dotnet/bin"), "dotnet executable is directly in its root")
}

func testShellEscaping() throws {
    let backtick = "\u{60}"
    try expectEqual(EnvironmentScript.shellDoubleQuoted("a$b"), "a\\$b")
    try expectEqual(EnvironmentScript.shellDoubleQuoted("a\"b"), "a\\\"b")
    try expectEqual(EnvironmentScript.shellDoubleQuoted("a\\b"), "a\\\\b")
    try expectEqual(EnvironmentScript.shellDoubleQuoted("a\(backtick)b"), "a\\\(backtick)b")

    let script = EnvironmentScript.content(
        languageName: "Weird",
        version: "1.0.0",
        runtimePath: "/tmp/weird $VAR \"quote\"/1.0.0",
        environmentVariableName: "WEIRD_HOME",
        pathSuffix: "bin"
    )
    try expect(
        script.contains(
            "export WEIRD_HOME=\"/tmp/weird \\$VAR \\\"quote\\\"/1.0.0\""),
        "double-quoted runtime path must be escaped")
}

func testPathEntry() throws {
    try expectEqual(
        EnvironmentScript.pathEntry(runtimePath: "/opt/go", pathSuffix: "bin"), "/opt/go/bin")
    try expectEqual(
        EnvironmentScript.pathEntry(runtimePath: "/usr/local/share/dotnet", pathSuffix: ""),
        "/usr/local/share/dotnet")
    try expectEqual(
        EnvironmentScript.pathEntry(runtimePath: "/opt/go", pathSuffix: "/bin/"), "/opt/go/bin")
}

// MARK: - Config validation

func testConfigValidation() throws {
    try expect(
        LanguageConfigValidation.validate(
            name: "Node.js",
            identifier: "node",
            scanPaths: ["/opt/homebrew/Cellar/node*"],
            envVarName: "NODE_HOME"
        ).isEmpty,
        "valid config")

    try expectEqual(
        LanguageConfigValidation.validate(
            name: "", identifier: "", scanPaths: [], envVarName: nil),
        [
            .nameRequired,
            .identifierRequired,
            .scanPathRequired,
        ]
    )

    try expectEqual(
        LanguageConfigValidation.validate(
            name: "Node", identifier: "node js", scanPaths: ["/tmp"], envVarName: "NODE_HOME"),
        [.identifierInvalid]
    )

    try expectEqual(
        LanguageConfigValidation.validate(
            name: "Node", identifier: "node", scanPaths: ["/tmp"], envVarName: "NODE HOME"),
        [.environmentVariableInvalid]
    )

    try expectEqual(
        LanguageConfigValidation.validate(
            name: "Node", identifier: "node", scanPaths: ["/tmp"], envVarName: "HOME"),
        [.environmentVariableReserved]
    )

    try expect(
        !LanguageConfigValidation.isValidIdentifier("has space"),
        "space is invalid in identifier")
    try expect(
        LanguageConfigValidation.isValidEnvironmentVariableName("JAVA_HOME"),
        "JAVA_HOME is valid")
    try expect(
        !LanguageConfigValidation.isValidEnvironmentVariableName("JAVA-HOME"),
        "hyphen is invalid in env var name")
}

func testDotnetRootResolution() throws {
    let root = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    let sdkVersion = root.appendingPathComponent("sdk/8.0.100", isDirectory: true)
    try FileManager.default.createDirectory(at: sdkVersion, withIntermediateDirectories: true)

    try expectEqual(
        RuntimePathResolution.dotnetRoot(fromVersionPath: sdkVersion.path),
        sdkVersion.path,
        "without dotnet executable the SDK path is kept")

    let dotnet = root.appendingPathComponent("dotnet")
    FileManager.default.createFile(atPath: dotnet.path, contents: nil)

    try expectEqual(
        RuntimePathResolution.dotnetRoot(fromVersionPath: sdkVersion.path),
        root.path,
        "with dotnet executable DOTNET_ROOT is the root")

    try expectEqual(
        RuntimePathResolution.dotnetRoot(fromVersionPath: root.appendingPathComponent("other").path),
        root.appendingPathComponent("other").path,
        "non-sdk path is unchanged")
}

func testRustMigration() throws {
    try expectNil(
        LanguageConfigMigration.migratedRustEnvironmentVariable(
            currentEnvironmentVariable: "RUSTUP_HOME",
            scanPaths: ["~/.rustup/toolchains"]
        ),
        "old rustup config drops RUSTUP_HOME")

    try expectEqual(
        LanguageConfigMigration.migratedRustEnvironmentVariable(
            currentEnvironmentVariable: "RUSTUP_HOME",
            scanPaths: ["/opt/homebrew/Cellar/rust*"]
        ),
        "RUSTUP_HOME",
        "unrelated custom config is untouched")

    try expectEqual(
        LanguageConfigMigration.migratedRustEnvironmentVariable(
            currentEnvironmentVariable: "JAVA_HOME",
            scanPaths: ["~/.rustup/toolchains"]
        ),
        "JAVA_HOME",
        "other env vars are untouched")
}

// MARK: - Run

test("version sorting", testVersionSorting)
test("version extraction", testVersionExtraction)
test("rust toolchain detection", testRustToolchainDetection)
test("brew formula matching", testBrewFormulaMatching)
test("flutter SDK detection", testFlutterSDKDetection)
test("script with env var", testScriptWithEnvironmentVariable)
test("script without env var", testScriptWithoutEnvironmentVariable)
test("script with empty path suffix", testScriptWithRootPathSuffix)
test("shell escaping", testShellEscaping)
test("path entry", testPathEntry)
test("config validation", testConfigValidation)
test(".NET root resolution", testDotnetRootResolution)
test("Rust config migration", testRustMigration)

if failures.isEmpty {
    print("All \(testCount) checks passed.")
    exit(0)
} else {
    print("\(failures.count) failed, \(testCount) total:")
    for failure in failures {
        print("  - \(failure)")
    }
    exit(1)
}
