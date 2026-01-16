import SwiftUI

// MARK: - Language Metadata

/// 语言元数据，包含UI配置和语言特性信息
struct LanguageMetadata: Identifiable {
    let id: String
    let displayName: String
    let iconName: String
    let color: Color
    let configFileName: String
    let order: Int

    init(
        id: String,
        displayName: String,
        iconName: String,
        color: Color,
        configFileName: String,
        order: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.iconName = iconName
        self.color = color
        self.configFileName = configFileName
        self.order = order
    }
}
