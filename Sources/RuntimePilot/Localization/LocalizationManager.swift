import Foundation
import SwiftUI

// MARK: - App Language

/// 支持的应用语言
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文简体"
        }
    }

    var nativeDisplayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文简体"
        }
    }
}

// MARK: - Localization Manager

/// 本地化管理器 - 管理应用语言设置
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private let userDefaultsKey = "AppLanguage"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
        }
    }

    private var translations: [AppLanguage: [String: String]] = [:]

    private init() {
        // 从 UserDefaults 加载保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: userDefaultsKey),
            let language = AppLanguage(rawValue: savedLanguage)
        {
            self.currentLanguage = language
        } else {
            // 默认使用英文
            self.currentLanguage = .english
        }

        // 加载翻译
        loadTranslations()
    }

    private func loadTranslations() {
        translations[.english] = englishStrings
        translations[.chinese] = chineseStrings
    }

    /// 获取本地化字符串
    func localized(_ key: LocalizedKey) -> String {
        return translations[currentLanguage]?[key.rawValue] ?? key.rawValue
    }

    /// 获取带参数的本地化字符串
    func localized(_ key: LocalizedKey, args: CVarArg...) -> String {
        let format = translations[currentLanguage]?[key.rawValue] ?? key.rawValue
        return String(format: format, arguments: args)
    }

    /// 设置语言
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
}

// MARK: - English Strings

private let englishStrings: [String: String] = [
    // App
    "app.name": "RuntimePilot",
    "app.tagline": "Dev Environment Manager",

    // Navigation
    "nav.dashboard": "Dashboard",
    "nav.environments": "ENVIRONMENTS",
    "nav.customLanguages": "CUSTOM LANGUAGES",
    "nav.selectEnvironment": "Select an Environment",
    "nav.selectEnvironmentHint": "Choose a language from the sidebar to manage versions",
    "nav.settings": "Settings",

    // Dashboard
    "dashboard.title": "Dashboard",
    "dashboard.subtitle": "Manage your development environments",
    "dashboard.environments": "Environments",
    "dashboard.selectLanguage": "Select a language to manage versions",
    "dashboard.quickStart": "Quick Start",
    "dashboard.shellSetup": "One-time shell setup",
    "dashboard.active": "Active",
    "dashboard.installed": "Installed",
    "dashboard.languages": "Languages",
    "dashboard.welcome": "Welcome to RuntimePilot",
    "dashboard.setupSteps": "Set up in 3 steps",
    "dashboard.step1.title": "Grant Access",
    "dashboard.step1.desc": "Allow RuntimePilot to scan version directories",
    "dashboard.step2.title": "Scan Versions",
    "dashboard.step2.desc": "Automatically detect installed versions",
    "dashboard.step3.title": "Switch Versions",
    "dashboard.step3.desc": "Easily switch between versions",
    "dashboard.getStarted": "Get Started",
    "dashboard.noVersions": "No versions detected",
    "dashboard.grantAccess": "Grant directory access to scan for installed versions",
    "dashboard.manageAccess": "Manage Access",

    // Quick Start
    "quickStart.label": "Set up in 3 steps",
    "quickStart.time": "~2 min",
    "quickStart.step1.title": "Select a version",
    "quickStart.step1.detail":
        "Click a language on the left, then press Use on the version you want to activate.",
    "quickStart.step2.title": "Configure your shell",
    "quickStart.step2.detail":
        "Add the snippet below to your shell config file (e.g. ~/.zshrc or ~/.bash_profile).",
    "quickStart.step3.title": "Activate",
    "quickStart.step3.detail": "Restart your terminal or run: source ~/.zshrc",

    // Welcome Card
    "welcome.hint": "Pick a language below, then select a version to get started.",

    // Environment Card
    "envCard.notConfigured": "Not configured",
    "envCard.notInstalled": "Not installed",
    "envCard.source": "Source",
    "envCard.installed": "Installed",
    "envCard.active": "Active",
    "envCard.select": "Select",
    "envCard.install": "Install",

    // Generic Language View
    "language.noVersionsFound": "No %@ Versions Found",
    "language.installHint":
        "Install versions using Homebrew, NVM, pyenv, or other version managers, then refresh.",
    "language.manageVersions": "Manage installed versions and your active environment",
    "language.active": "Active",
    "language.source": "Source",
    "language.path": "Path",
    "language.refresh": "Refresh",
    "language.noActiveVersion": "No active version",
    "language.current": "CURRENT",
    "language.use": "Use",
    "language.versions": "versions",

    // Shared Views
    "shared.homebrew": "Homebrew",
    "shared.setupRequired": "Setup Required",
    "shared.copyPath": "Copy Path",
    "shared.revealInFinder": "Reveal in Finder",
    "shared.authorizedDirectories": "Authorized Directories",
    "shared.loading": "Loading...",
    "shared.error": "Error",
    "shared.success": "Success",
    "shared.cancel": "Cancel",
    "shared.save": "Save",
    "shared.delete": "Delete",
    "shared.edit": "Edit",
    "shared.add": "Add",
    "shared.remove": "Remove",
    "shared.done": "Done",
    "shared.close": "Close",
    "shared.skip": "Skip",
    "shared.continue": "Continue",
    "shared.back": "Back",

    // Onboarding
    "onboarding.welcome": "Welcome to RuntimePilot",
    "onboarding.grantAccess": "Grant Access",
    "onboarding.needsAccess": "RuntimePilot needs access to scan version directories:",
    "onboarding.skipForNow": "Skip for Now",
    "onboarding.continue": "Continue",
    "onboarding.selectFolder": "Select Folder",
    "onboarding.authorized": "Authorized",
    "onboarding.notAuthorized": "Not Authorized",
    "onboarding.chooseLanguages": "Choose which programming languages you want to manage",
    "onboarding.directoryAccess": "Directory Access",
    "onboarding.languageHint": "You can always add or remove languages later in Settings",
    "onboarding.directoryHint":
        "Grant access to directories where your language versions are installed",
    "onboarding.directoryList": "Recommended directories to authorize:",
    "onboarding.accessNote": "Access is required for RuntimePilot to scan and manage your versions",
    "onboarding.selected": "selected",

    // Settings
    "settings.title": "Settings",
    "settings.general": "General",
    "settings.language": "Language",
    "settings.languageDescription": "Choose your preferred interface language",
    "settings.appearance": "Appearance",
    "settings.about": "About",
    "settings.scanPaths": "Scan Paths",
    "settings.authorizedDirs": "Authorized Directories",
    "settings.noDirs": "No directories authorized yet",
    "settings.addDir": "Add Directory",

    // Scan Paths
    "scanPath.description":
        "Manage version scan paths for each language. Built-in paths cannot be modified, but you can add custom paths.",
    "scanPath.builtIn": "Default Scan Paths",
    "scanPath.custom": "Custom Scan Paths",
    "scanPath.noCustom": "No custom paths added",
    "scanPath.addCustom": "Add Custom Path",
    "scanPath.placeholder": "~/path/to/versions",
    "scanPath.selectFolder": "Select a directory to scan for versions",
    "scanPath.exists": "Available",
    "scanPath.notExists": "Not found",
    "scanPath.needsAuth": "Needs authorization",
    "scanPath.versionCount": "%d versions found",
    "scanPath.scanning": "Scanning...",
    "scanPath.summary": "%d paths, %d available",
    "scanPath.noLanguages": "No languages configured",
    "scanPath.addLanguageHint": "Add languages from the sidebar to configure scan paths",
    "scanPath.configured": "Configured Paths",
    "scanPath.noConfigured": "No paths configured",

    // Language Names
    "language.java": "Java JDK",
    "language.node": "Node.js",
    "language.python": "Python",
    "language.go": "Go",

    // Custom Language
    "customLanguage.title": "Custom Languages",
    "customLanguage.add": "Add Language",
    "customLanguage.edit": "Edit Language",
    "customLanguage.name": "Name",
    "customLanguage.namePlaceholder": "e.g. Ruby",
    "customLanguage.identifier": "Identifier",
    "customLanguage.identifierPlaceholder": "e.g. ruby",
    "customLanguage.icon": "Icon",
    "customLanguage.color": "Color",
    "customLanguage.scanPaths": "Scan Paths",
    "customLanguage.addPath": "Add Path",
    "customLanguage.envVar": "Environment Variable",
    "customLanguage.envVarPlaceholder": "e.g. RUBY_HOME",
    "customLanguage.preview": "Preview",
    "customLanguage.deleteConfirm": "Are you sure you want to delete this language?",
    "customLanguage.noCustomLanguages": "No custom languages",
    "customLanguage.addHint": "Click + to add a custom language",

    // Menu
    "menu.tools": "Tools",
    "menu.refreshAll": "Refresh All",
    "menu.manageDirectoryAccess": "Manage Directory Access...",
    "menu.about": "About RuntimePilot",

    // Version Switch Toast
    "versionSwitch.title": "Version Switched",
    "versionSwitch.message": "%@ %@ is now active. Environment variables have been updated. Open a new terminal to use the new version.",
    "versionSwitch.openTerminal": "Open Terminal",
    "versionSwitch.dismiss": "Dismiss",
]

// MARK: - Chinese Strings

private let chineseStrings: [String: String] = [
    // App
    "app.name": "RuntimePilot",
    "app.tagline": "开发环境管理器",

    // Navigation
    "nav.dashboard": "仪表盘",
    "nav.environments": "开发环境",
    "nav.customLanguages": "自定义语言",
    "nav.selectEnvironment": "选择一个环境",
    "nav.selectEnvironmentHint": "从侧边栏选择一种语言来管理版本",
    "nav.settings": "设置",

    // Dashboard
    "dashboard.title": "仪表盘",
    "dashboard.subtitle": "管理您的开发环境",
    "dashboard.environments": "开发环境",
    "dashboard.selectLanguage": "选择一种语言来管理版本",
    "dashboard.quickStart": "快速开始",
    "dashboard.shellSetup": "一次性 Shell 配置",
    "dashboard.active": "已激活",
    "dashboard.installed": "已安装",
    "dashboard.languages": "语言",
    "dashboard.welcome": "欢迎使用 RuntimePilot",
    "dashboard.setupSteps": "3 步完成设置",
    "dashboard.step1.title": "授权访问",
    "dashboard.step1.desc": "允许 RuntimePilot 扫描版本目录",
    "dashboard.step2.title": "扫描版本",
    "dashboard.step2.desc": "自动检测已安装的版本",
    "dashboard.step3.title": "切换版本",
    "dashboard.step3.desc": "轻松切换不同版本",
    "dashboard.getStarted": "开始使用",
    "dashboard.noVersions": "未检测到版本",
    "dashboard.grantAccess": "授权目录访问以扫描已安装的版本",
    "dashboard.manageAccess": "管理权限",

    // Quick Start
    "quickStart.label": "3 步完成配置",
    "quickStart.time": "约 2 分钟",
    "quickStart.step1.title": "选择版本",
    "quickStart.step1.detail": "点击左侧的语言，然后在想要激活的版本上点击「使用」按钮。",
    "quickStart.step2.title": "配置 Shell",
    "quickStart.step2.detail": "将下方代码片段添加到你的 Shell 配置文件（如 ~/.zshrc 或 ~/.bash_profile）。",
    "quickStart.step3.title": "激活生效",
    "quickStart.step3.detail": "重启终端，或运行命令：source ~/.zshrc",

    // Welcome Card
    "welcome.hint": "在下方选择一个语言，然后选择一个版本开始使用。",

    // Environment Card
    "envCard.notConfigured": "未配置",
    "envCard.notInstalled": "未安装",
    "envCard.source": "来源",
    "envCard.installed": "已安装",
    "envCard.active": "已激活",
    "envCard.select": "选择",
    "envCard.install": "安装",

    // Generic Language View
    "language.noVersionsFound": "未找到 %@ 版本",
    "language.installHint": "使用 Homebrew、NVM、pyenv 或其他版本管理器安装版本，然后刷新。",
    "language.manageVersions": "管理已安装的版本和当前激活的环境",
    "language.active": "激活",
    "language.source": "来源",
    "language.path": "路径",
    "language.refresh": "刷新",
    "language.noActiveVersion": "无激活版本",
    "language.current": "当前",
    "language.use": "使用",
    "language.versions": "个版本",

    // Shared Views
    "shared.homebrew": "Homebrew",
    "shared.setupRequired": "需要配置",
    "shared.copyPath": "复制路径",
    "shared.revealInFinder": "在 Finder 中显示",
    "shared.authorizedDirectories": "已授权目录",
    "shared.loading": "加载中...",
    "shared.error": "错误",
    "shared.success": "成功",
    "shared.cancel": "取消",
    "shared.save": "保存",
    "shared.delete": "删除",
    "shared.edit": "编辑",
    "shared.add": "添加",
    "shared.remove": "移除",
    "shared.done": "完成",
    "shared.close": "关闭",
    "shared.skip": "跳过",
    "shared.continue": "继续",
    "shared.back": "返回",

    // Onboarding
    "onboarding.welcome": "欢迎使用 RuntimePilot",
    "onboarding.grantAccess": "授予访问权限",
    "onboarding.needsAccess": "RuntimePilot 需要访问以下目录来扫描版本：",
    "onboarding.skipForNow": "暂时跳过",
    "onboarding.continue": "继续",
    "onboarding.selectFolder": "选择文件夹",
    "onboarding.authorized": "已授权",
    "onboarding.notAuthorized": "未授权",
    "onboarding.chooseLanguages": "选择您要管理的编程语言",
    "onboarding.directoryAccess": "目录访问权限",
    "onboarding.languageHint": "您可以随时在设置中添加或移除语言",
    "onboarding.directoryHint": "授权访问安装了语言版本的目录",
    "onboarding.directoryList": "推荐授权的目录：",
    "onboarding.accessNote": "RuntimePilot 需要访问权限来扫描和管理您的版本",
    "onboarding.selected": "已选择",

    // Settings
    "settings.title": "设置",
    "settings.general": "通用",
    "settings.language": "语言",
    "settings.languageDescription": "选择您偏好的界面语言",
    "settings.appearance": "外观",
    "settings.about": "关于",
    "settings.scanPaths": "扫描路径",
    "settings.authorizedDirs": "已授权的目录",
    "settings.noDirs": "尚未授权任何目录",
    "settings.addDir": "添加目录",

    // Scan Paths
    "scanPath.description": "管理各语言的版本扫描路径。内置路径不可修改，但您可以添加自定义路径。",
    "scanPath.builtIn": "默认扫描路径",
    "scanPath.custom": "自定义扫描路径",
    "scanPath.noCustom": "未添加自定义路径",
    "scanPath.addCustom": "添加自定义路径",
    "scanPath.placeholder": "~/path/to/versions",
    "scanPath.selectFolder": "选择要扫描的版本目录",
    "scanPath.exists": "可用",
    "scanPath.notExists": "未找到",
    "scanPath.needsAuth": "需要授权",
    "scanPath.versionCount": "找到 %d 个版本",
    "scanPath.scanning": "扫描中...",
    "scanPath.summary": "%d 个路径，%d 个可用",
    "scanPath.noLanguages": "未配置任何语言",
    "scanPath.addLanguageHint": "从侧边栏添加语言以配置扫描路径",
    "scanPath.configured": "已配置的路径",
    "scanPath.noConfigured": "未配置路径",

    // Language Names
    "language.java": "Java JDK",
    "language.node": "Node.js",
    "language.python": "Python",
    "language.go": "Go",

    // Custom Language
    "customLanguage.title": "自定义语言",
    "customLanguage.add": "添加语言",
    "customLanguage.edit": "编辑语言",
    "customLanguage.name": "名称",
    "customLanguage.namePlaceholder": "例如：Ruby",
    "customLanguage.identifier": "标识符",
    "customLanguage.identifierPlaceholder": "例如：ruby",
    "customLanguage.icon": "图标",
    "customLanguage.color": "颜色",
    "customLanguage.scanPaths": "扫描路径",
    "customLanguage.addPath": "添加路径",
    "customLanguage.envVar": "环境变量",
    "customLanguage.envVarPlaceholder": "例如：RUBY_HOME",
    "customLanguage.preview": "预览",
    "customLanguage.deleteConfirm": "确定要删除这个语言吗？",
    "customLanguage.noCustomLanguages": "没有自定义语言",
    "customLanguage.addHint": "点击 + 添加自定义语言",

    // Menu
    "menu.tools": "工具",
    "menu.refreshAll": "刷新全部",
    "menu.manageDirectoryAccess": "管理目录访问权限...",
    "menu.about": "关于 RuntimePilot",

    // Version Switch Toast
    "versionSwitch.title": "版本已切换",
    "versionSwitch.message": "%@ %@ 已激活。环境变量已更新，需要打开新终端才能使用新版本。",
    "versionSwitch.openTerminal": "打开终端",
    "versionSwitch.dismiss": "知道了",
]
