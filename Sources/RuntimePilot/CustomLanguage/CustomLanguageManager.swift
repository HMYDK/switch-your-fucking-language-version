import Combine
import Foundation
import SwiftUI

// MARK: - Custom Language Manager

/// 自定义语言管理器 - 管理用户添加的自定义编程语言
final class CustomLanguageManager: ObservableObject {
    static let shared = CustomLanguageManager()

    private let userDefaultsKey = "CustomLanguages"
    private let customLanguageIdsKey = "CustomLanguageIds"

    @Published private(set) var customLanguages: [CustomLanguageConfig] = []
    @Published private(set) var versionManagers: [String: CustomVersionManager] = [:]

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadFromUserDefaults()
    }

    // MARK: - Persistence

    /// 从 UserDefaults 加载配置
    private func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            let configs = try JSONDecoder().decode([CustomLanguageConfig].self, from: data)
            self.customLanguages = configs.sorted { $0.order < $1.order }

            // 为每个配置创建版本管理器
            for config in customLanguages {
                createVersionManager(for: config)
            }
        } catch {
            print("Failed to load custom languages: \(error)")
        }
    }

    /// 保存到 UserDefaults
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(customLanguages)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save custom languages: \(error)")
        }
    }

    // MARK: - CRUD Operations

    /// 添加新语言
    func addLanguage(_ config: CustomLanguageConfig) {
        var newConfig = config
        // 确保有唯一的 order
        if customLanguages.isEmpty {
            newConfig.order = 100
        } else {
            newConfig.order = (customLanguages.map { $0.order }.max() ?? 99) + 1
        }

        customLanguages.append(newConfig)
        customLanguages.sort { $0.order < $1.order }
        createVersionManager(for: newConfig)
        saveToUserDefaults()
    }

    /// 更新语言配置
    func updateLanguage(_ config: CustomLanguageConfig) {
        guard let index = customLanguages.firstIndex(where: { $0.id == config.id }) else {
            return
        }

        let oldIdentifier = customLanguages[index].identifier
        customLanguages[index] = config

        // 如果 identifier 变了，需要更新版本管理器的键
        if oldIdentifier != config.identifier {
            if let manager = versionManagers.removeValue(forKey: oldIdentifier) {
                versionManagers[config.identifier] = manager
                manager.updateConfig(config)
            }
        } else {
            versionManagers[config.identifier]?.updateConfig(config)
        }

        saveToUserDefaults()
    }

    /// 删除语言
    func deleteLanguage(id: UUID) {
        guard let index = customLanguages.firstIndex(where: { $0.id == id }) else {
            return
        }

        let config = customLanguages[index]
        versionManagers.removeValue(forKey: config.identifier)
        customLanguages.remove(at: index)
        saveToUserDefaults()
    }

    /// 根据 ID 获取配置
    func getConfig(id: UUID) -> CustomLanguageConfig? {
        customLanguages.first { $0.id == id }
    }

    /// 根据 identifier 获取配置
    func getConfig(identifier: String) -> CustomLanguageConfig? {
        customLanguages.first { $0.identifier == identifier }
    }

    /// 获取版本管理器
    func getVersionManager(for identifier: String) -> CustomVersionManager? {
        versionManagers[identifier]
    }

    /// 检查 identifier 是否已存在
    func isIdentifierExists(_ identifier: String, excludingId: UUID? = nil) -> Bool {
        customLanguages.contains { config in
            config.identifier == identifier && config.id != excludingId
        }
    }

    // MARK: - Version Manager

    /// 为配置创建版本管理器
    private func createVersionManager(for config: CustomLanguageConfig) {
        let manager = CustomVersionManager(config: config)
        versionManagers[config.identifier] = manager
    }

    // MARK: - Registry Integration

    /// 将所有自定义语言注册到 LanguageRegistry
    func registerToRegistry(_ registry: LanguageRegistry) {
        for config in customLanguages {
            if let manager = versionManagers[config.identifier] {
                let metadata = config.toMetadata()
                registry.register(metadata: metadata, manager: manager)
            }
        }
    }

    /// 从 LanguageRegistry 注销所有自定义语言
    func unregisterFromRegistry(_ registry: LanguageRegistry) {
        for config in customLanguages {
            registry.unregister(id: config.identifier)
        }
    }

    /// 刷新所有自定义语言的版本
    func refreshAll() {
        for manager in versionManagers.values {
            manager.refresh()
        }
    }
}

// MARK: - Custom Language Identifiers Tracking

extension CustomLanguageManager {
    /// 获取所有自定义语言的 identifier 列表
    var customLanguageIds: Set<String> {
        Set(customLanguages.map { $0.identifier })
    }

    /// 检查给定的 id 是否是自定义语言
    func isCustomLanguage(_ identifier: String) -> Bool {
        customLanguageIds.contains(identifier)
    }
}
