import Foundation

/// 数据迁移管理器 - 处理从旧版本内置语言到新版本自定义语言的迁移
final class MigrationManager {
    static let shared = MigrationManager()
    
    private let migratedKey = "HasMigratedBuiltInLanguages"
    private let migrationVersionKey = "MigrationVersion"
    private let currentMigrationVersion = "2.0"
    
    private init() {}
    
    /// 检查并执行迁移（如果需要）
    func migrateIfNeeded() {
        // 如果已经迁移过，跳过
        if UserDefaults.standard.bool(forKey: migratedKey) {
            return
        }
        
        performMigration()
    }
    
    /// 强制重新迁移（用于设置中的重置功能）
    func forceMigrate() {
        UserDefaults.standard.set(false, forKey: migratedKey)
        performMigration()
    }
    
    /// 执行迁移
    private func performMigration() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("devmanager")
        
        // 旧配置文件映射到新模板
        let oldConfigs: [(fileName: String, template: LanguageTemplate, activeVersionKey: String)] = [
            ("java_env.sh", .java, "ActiveJavaVersion"),
            ("node_env.sh", .node, "ActiveNodeVersion"),
            ("python_env.sh", .python, "ActivePythonVersion"),
            ("go_env.sh", .go, "ActiveGoVersion")
        ]
        
        var migratedCount = 0
        
        for (fileName, template, oldActiveKey) in oldConfigs {
            let filePath = configDir.appendingPathComponent(fileName)
            
            // 检查旧配置文件是否存在
            if FileManager.default.fileExists(atPath: filePath.path) {
                migrateLanguage(template: template, configFilePath: filePath, oldActiveKey: oldActiveKey)
                migratedCount += 1
            }
        }
        
        // 标记迁移完成
        UserDefaults.standard.set(true, forKey: migratedKey)
        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
        
        if migratedCount > 0 {
            print("Migration completed: \(migratedCount) language(s) migrated")
        }
    }
    
    /// 迁移单个语言
    private func migrateLanguage(template: LanguageTemplate, configFilePath: URL, oldActiveKey: String) {
        let manager = CustomLanguageManager.shared
        
        // 检查是否已存在同名语言
        if manager.isIdentifierExists(template.id) {
            print("Language \(template.id) already exists, skipping migration")
            return
        }
        
        // 创建配置
        var config = template.config
        config.id = UUID()
        
        // 添加语言
        manager.addLanguage(config)
        
        // 尝试恢复激活版本
        restoreActiveVersion(for: config, configFilePath: configFilePath, oldActiveKey: oldActiveKey)
    }
    
    /// 恢复激活版本
    private func restoreActiveVersion(for config: CustomLanguageConfig, configFilePath: URL, oldActiveKey: String) {
        // 方法1: 从旧的 UserDefaults 键读取
        if let oldActivePath = UserDefaults.standard.string(forKey: oldActiveKey) {
            // 保存到新的键
            UserDefaults.standard.set(oldActivePath, forKey: "ActiveVersion_\(config.identifier)")
            return
        }
        
        // 方法2: 从配置文件解析
        if let activePath = parseActivePathFromConfigFile(configFilePath, envVarName: config.envVarName) {
            UserDefaults.standard.set(activePath, forKey: "ActiveVersion_\(config.identifier)")
        }
    }
    
    /// 从配置文件解析激活版本路径
    private func parseActivePathFromConfigFile(_ filePath: URL, envVarName: String?) -> String? {
        guard let envVar = envVarName,
              let content = try? String(contentsOf: filePath, encoding: .utf8) else {
            return nil
        }
        
        // 查找 export JAVA_HOME="..." 或类似格式
        let patterns = [
            "export \(envVar)=\"([^\"]+)\"",
            "export \(envVar)='([^']+)'",
            "export \(envVar)=([^\\s]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let range = Range(match.range(at: 1), in: content) {
                return String(content[range])
            }
        }
        
        return nil
    }
    
    /// 检查是否需要显示首次使用引导
    var needsOnboarding: Bool {
        // 如果没有任何自定义语言，且没有完成过引导
        return CustomLanguageManager.shared.customLanguages.isEmpty
            && !UserDefaults.standard.bool(forKey: "HasCompletedLanguageOnboarding")
    }
    
    /// 标记引导完成
    func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: "HasCompletedLanguageOnboarding")
    }
    
    /// 重置迁移状态（用于调试）
    func resetMigrationState() {
        UserDefaults.standard.removeObject(forKey: migratedKey)
        UserDefaults.standard.removeObject(forKey: migrationVersionKey)
        UserDefaults.standard.removeObject(forKey: "HasCompletedLanguageOnboarding")
    }
}
