import Combine
import Foundation
import SwiftUI

// MARK: - Language Status Model

struct LanguageStatus: Identifiable {
    let id: String
    let displayName: String
    let iconName: String
    let iconType: IconType
    let color: Color
    let activeVersion: String?
    let activeSource: String?
    let installedCount: Int

    var isConfigured: Bool {
        activeVersion != nil
    }
}

// MARK: - Dashboard ViewModel

class DashboardViewModel: ObservableObject {
    @Published private(set) var languageStatuses: [LanguageStatus] = []

    private let registry: LanguageRegistry
    private var cancellables = Set<AnyCancellable>()
    private var managerCancellables = Set<AnyCancellable>()

    init(registry: LanguageRegistry) {
        self.registry = registry

        // @Published 在 willSet 阶段发值；如果同步读取 registry.allLanguages
        // 仍然会拿到旧列表。推迟到下一个主线程周期再刷新。
        registry.$languages
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.setupManagerObservers()
                    self?.updateStatuses()
                }
            }
            .store(in: &cancellables)

        updateStatuses()
        setupManagerObservers()
    }

    private func setupManagerObservers() {
        // registry 变更不频繁，直接重建监听，避免 id 复用后仍监听旧 manager
        managerCancellables.removeAll()
        for language in registry.allLanguages {
            language.manager.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.updateStatuses()
                    }
                }
                .store(in: &managerCancellables)
        }
    }

    private func updateStatuses() {
        languageStatuses = registry.allLanguages.map { language in
            let metadata = language.metadata
            let manager = language.manager

            return LanguageStatus(
                id: metadata.id,
                displayName: metadata.displayName,
                iconName: metadata.iconName,
                iconType: metadata.iconType,
                color: metadata.color,
                activeVersion: manager.activeVersion?.version,
                activeSource: manager.activeVersion?.source,
                installedCount: manager.installedVersions.count
            )
        }
    }

    var hasAnyConfigured: Bool {
        languageStatuses.contains { $0.isConfigured }
    }
}
