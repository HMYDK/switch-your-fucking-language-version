import Foundation

/// 将旧版本保存的配置迁移到新的语义。
public enum LanguageConfigMigration {

    /// 旧 Rust 模板把 RUSTUP_HOME 指向单个 toolchain，会破坏 rustup。
    /// 迁移为不设置该环境变量，仅通过 PATH 选择 toolchain。
    public static func migratedRustEnvironmentVariable(
        currentEnvironmentVariable: String?,
        scanPaths: [String]
    ) -> String? {
        guard currentEnvironmentVariable == "RUSTUP_HOME" else {
            return currentEnvironmentVariable
        }
        let usesRustupToolchains = scanPaths.contains {
            $0.lowercased().contains(".rustup/toolchains")
        }
        return usesRustupToolchains ? nil : currentEnvironmentVariable
    }
}
