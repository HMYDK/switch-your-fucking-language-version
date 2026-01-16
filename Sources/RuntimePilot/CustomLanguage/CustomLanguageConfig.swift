import Foundation
import SwiftUI

// MARK: - Custom Language Config

/// 自定义语言配置
struct CustomLanguageConfig: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var identifier: String
    var iconSymbol: String
    var colorHex: String
    var scanPaths: [String]
    var envVarName: String?
    var configFileName: String
    var order: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        identifier: String = "",
        iconSymbol: String = "cube.fill",
        colorHex: String = "#007AFF",
        scanPaths: [String] = [],
        envVarName: String? = nil,
        configFileName: String = "",
        order: Int = 100
    ) {
        self.id = id
        self.name = name
        self.identifier = identifier
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.scanPaths = scanPaths
        self.envVarName = envVarName
        self.configFileName = configFileName
        self.order = order
    }

    /// 从十六进制字符串获取颜色
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    /// 生成配置文件名
    var generatedConfigFileName: String {
        if configFileName.isEmpty {
            return "\(identifier)_env.sh"
        }
        return configFileName
    }

    /// 展开扫描路径中的 ~ 符号
    var expandedScanPaths: [String] {
        scanPaths.map { path in
            if path.hasPrefix("~") {
                return (path as NSString).expandingTildeInPath
            }
            return path
        }
    }

    /// 转换为 LanguageMetadata
    func toMetadata() -> LanguageMetadata {
        LanguageMetadata(
            id: identifier,
            displayName: name,
            iconName: iconSymbol,
            color: color,
            configFileName: generatedConfigFileName,
            order: order,
            isCustom: true,
            iconType: .systemSymbol
        )
    }

    /// 验证配置是否有效
    var isValid: Bool {
        !name.isEmpty && !identifier.isEmpty && !scanPaths.isEmpty
    }

    /// 验证错误信息
    var validationErrors: [String] {
        var errors: [String] = []
        if name.isEmpty {
            errors.append("Name is required")
        }
        if identifier.isEmpty {
            errors.append("Identifier is required")
        }
        if scanPaths.isEmpty {
            errors.append("At least one scan path is required")
        }
        return errors
    }
}

// MARK: - Color Extension

extension Color {
    /// 从十六进制字符串创建颜色
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// 转换为十六进制字符串
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Icon Type

/// 图标类型
enum IconType: String, Codable {
    case systemSymbol  // SF Symbol
    case customImage  // 自定义图片
}

// MARK: - Extended Language Metadata

extension LanguageMetadata {
    /// 是否为自定义语言
    private static var customFlagKey = "isCustom"
    private static var iconTypeKey = "iconType"

    init(
        id: String,
        displayName: String,
        iconName: String,
        color: Color,
        configFileName: String,
        order: Int = 0,
        isCustom: Bool = false,
        iconType: IconType = .customImage
    ) {
        self.init(
            id: id,
            displayName: displayName,
            iconName: iconName,
            color: color,
            configFileName: configFileName,
            order: order
        )
        // 注意: 由于 LanguageMetadata 是 struct，我们无法在这里存储额外属性
        // isCustom 和 iconType 将通过 CustomLanguageManager 来追踪
    }
}

// MARK: - Preset Language Templates

/// 预设语言模板，方便用户快速添加常见语言
enum LanguageTemplate: String, CaseIterable, Identifiable {
    case ruby
    case rust
    case php
    case dotnet
    case flutter

    var id: String { rawValue }

    var config: CustomLanguageConfig {
        switch self {
        case .ruby:
            return CustomLanguageConfig(
                name: "Ruby",
                identifier: "ruby",
                iconSymbol: "diamond.fill",
                colorHex: "#CC342D",
                scanPaths: [
                    "~/.rbenv/versions",
                    "~/.rvm/rubies",
                    "/usr/local/Cellar/ruby",
                ],
                envVarName: "RUBY_HOME",
                order: 100
            )
        case .rust:
            return CustomLanguageConfig(
                name: "Rust",
                identifier: "rust",
                iconSymbol: "gearshape.2.fill",
                colorHex: "#DEA584",
                scanPaths: [
                    "~/.rustup/toolchains"
                ],
                envVarName: "RUSTUP_HOME",
                order: 101
            )
        case .php:
            return CustomLanguageConfig(
                name: "PHP",
                identifier: "php",
                iconSymbol: "ellipsis.curlybraces",
                colorHex: "#777BB4",
                scanPaths: [
                    "/usr/local/Cellar/php",
                    "/opt/homebrew/Cellar/php",
                ],
                envVarName: "PHP_HOME",
                order: 102
            )
        case .dotnet:
            return CustomLanguageConfig(
                name: ".NET",
                identifier: "dotnet",
                iconSymbol: "square.stack.3d.up.fill",
                colorHex: "#512BD4",
                scanPaths: [
                    "/usr/local/share/dotnet/sdk",
                    "~/.dotnet/sdk",
                ],
                envVarName: "DOTNET_ROOT",
                order: 103
            )
        case .flutter:
            return CustomLanguageConfig(
                name: "Flutter",
                identifier: "flutter",
                iconSymbol: "bird.fill",
                colorHex: "#02569B",
                scanPaths: [
                    "~/flutter",
                    "/opt/flutter",
                ],
                envVarName: "FLUTTER_ROOT",
                order: 104
            )
        }
    }

    var displayName: String {
        config.name
    }
}
