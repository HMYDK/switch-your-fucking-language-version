import Combine
import Foundation
import SwiftUI

// MARK: - Language Status Model

struct LanguageStatus: Identifiable {
    let id: String
    let displayName: String
    let iconName: String
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
    
    init(registry: LanguageRegistry) {
        self.registry = registry
        
        // 监听 registry 的变化
        registry.$languages
            .sink { [weak self] _ in
                self?.updateStatuses()
            }
            .store(in: &cancellables)
        
        // 初始化状态
        updateStatuses()
        
        // 监听每个语言管理器的变化
        setupManagerObservers()
    }
    
    private func setupManagerObservers() {
        // 监听所有语言管理器的变化
        for language in registry.allLanguages {
            language.manager.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.updateStatuses()
                    }
                }
                .store(in: &cancellables)
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
