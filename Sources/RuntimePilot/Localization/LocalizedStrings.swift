import Foundation

// MARK: - Localized Key

/// 本地化字符串键
enum LocalizedKey: String {
    // App
    case appName = "app.name"
    case appTagline = "app.tagline"

    // Navigation
    case navDashboard = "nav.dashboard"
    case navEnvironments = "nav.environments"
    case navCustomLanguages = "nav.customLanguages"
    case navSelectEnvironment = "nav.selectEnvironment"
    case navSelectEnvironmentHint = "nav.selectEnvironmentHint"
    case navSettings = "nav.settings"

    // Dashboard
    case dashboardTitle = "dashboard.title"
    case dashboardSubtitle = "dashboard.subtitle"
    case dashboardEnvironments = "dashboard.environments"
    case dashboardSelectLanguage = "dashboard.selectLanguage"
    case dashboardQuickStart = "dashboard.quickStart"
    case dashboardShellSetup = "dashboard.shellSetup"
    case dashboardActive = "dashboard.active"
    case dashboardInstalled = "dashboard.installed"
    case dashboardLanguages = "dashboard.languages"
    case dashboardWelcome = "dashboard.welcome"
    case dashboardSetupSteps = "dashboard.setupSteps"
    case dashboardStep1Title = "dashboard.step1.title"
    case dashboardStep1Desc = "dashboard.step1.desc"
    case dashboardStep2Title = "dashboard.step2.title"
    case dashboardStep2Desc = "dashboard.step2.desc"
    case dashboardStep3Title = "dashboard.step3.title"
    case dashboardStep3Desc = "dashboard.step3.desc"
    case dashboardGetStarted = "dashboard.getStarted"
    case dashboardNoVersions = "dashboard.noVersions"
    case dashboardGrantAccess = "dashboard.grantAccess"
    case dashboardManageAccess = "dashboard.manageAccess"

    // Quick Start
    case quickStartLabel = "quickStart.label"
    case quickStartTime = "quickStart.time"
    case quickStartStep1Title = "quickStart.step1.title"
    case quickStartStep1Detail = "quickStart.step1.detail"
    case quickStartStep2Title = "quickStart.step2.title"
    case quickStartStep2Detail = "quickStart.step2.detail"
    case quickStartStep3Title = "quickStart.step3.title"
    case quickStartStep3Detail = "quickStart.step3.detail"

    // Welcome Card
    case welcomeHint = "welcome.hint"

    // Environment Card
    case envCardNotConfigured = "envCard.notConfigured"
    case envCardNotInstalled = "envCard.notInstalled"
    case envCardSource = "envCard.source"
    case envCardInstalled = "envCard.installed"
    case envCardActive = "envCard.active"
    case envCardSelect = "envCard.select"
    case envCardInstall = "envCard.install"

    // Generic Language View
    case languageNoVersionsFound = "language.noVersionsFound"
    case languageInstallHint = "language.installHint"
    case languageManageVersions = "language.manageVersions"
    case languageActive = "language.active"
    case languageSource = "language.source"
    case languagePath = "language.path"
    case languageRefresh = "language.refresh"
    case languageNoActiveVersion = "language.noActiveVersion"
    case languageCurrent = "language.current"
    case languageUse = "language.use"
    case languageVersions = "language.versions"

    // Shared Views
    case sharedHomebrew = "shared.homebrew"
    case sharedSetupRequired = "shared.setupRequired"
    case sharedCopyPath = "shared.copyPath"
    case sharedRevealInFinder = "shared.revealInFinder"
    case sharedAuthorizedDirectories = "shared.authorizedDirectories"
    case sharedLoading = "shared.loading"
    case sharedError = "shared.error"
    case sharedSuccess = "shared.success"
    case sharedCancel = "shared.cancel"
    case sharedSave = "shared.save"
    case sharedDelete = "shared.delete"
    case sharedEdit = "shared.edit"
    case sharedAdd = "shared.add"
    case sharedRemove = "shared.remove"
    case sharedDone = "shared.done"
    case sharedClose = "shared.close"
    case sharedSkip = "shared.skip"
    case sharedContinue = "shared.continue"
    case sharedBack = "shared.back"

    // Version Switch Toast
    case versionSwitchTitle = "versionSwitch.title"
    case versionSwitchMessage = "versionSwitch.message"
    case versionSwitchOpenTerminal = "versionSwitch.openTerminal"
    case versionSwitchDismiss = "versionSwitch.dismiss"

    // Onboarding
    case onboardingWelcome = "onboarding.welcome"
    case onboardingGrantAccess = "onboarding.grantAccess"
    case onboardingNeedsAccess = "onboarding.needsAccess"
    case onboardingSkipForNow = "onboarding.skipForNow"
    case onboardingContinue = "onboarding.continue"
    case onboardingSelectFolder = "onboarding.selectFolder"
    case onboardingAuthorized = "onboarding.authorized"
    case onboardingNotAuthorized = "onboarding.notAuthorized"
    case onboardingChooseLanguages = "onboarding.chooseLanguages"
    case onboardingDirectoryAccess = "onboarding.directoryAccess"
    case onboardingLanguageHint = "onboarding.languageHint"
    case onboardingDirectoryHint = "onboarding.directoryHint"
    case onboardingDirectoryList = "onboarding.directoryList"
    case onboardingAccessNote = "onboarding.accessNote"
    case onboardingSelected = "onboarding.selected"

    // Settings
    case settingsTitle = "settings.title"
    case settingsGeneral = "settings.general"
    case settingsLanguage = "settings.language"
    case settingsLanguageDescription = "settings.languageDescription"
    case settingsAppearance = "settings.appearance"
    case settingsAbout = "settings.about"
    case settingsScanPaths = "settings.scanPaths"
    case settingsAuthorizedDirs = "settings.authorizedDirs"
    case settingsNoDirs = "settings.noDirs"
    case settingsAddDir = "settings.addDir"

    // Scan Paths
    case scanPathDescription = "scanPath.description"
    case scanPathBuiltIn = "scanPath.builtIn"
    case scanPathCustom = "scanPath.custom"
    case scanPathNoCustom = "scanPath.noCustom"
    case scanPathAddCustom = "scanPath.addCustom"
    case scanPathPlaceholder = "scanPath.placeholder"
    case scanPathSelectFolder = "scanPath.selectFolder"
    case scanPathExists = "scanPath.exists"
    case scanPathNotExists = "scanPath.notExists"
    case scanPathNeedsAuth = "scanPath.needsAuth"
    case scanPathVersionCount = "scanPath.versionCount"
    case scanPathScanning = "scanPath.scanning"
    case scanPathSummary = "scanPath.summary"
    case scanPathNoLanguages = "scanPath.noLanguages"
    case scanPathAddLanguageHint = "scanPath.addLanguageHint"
    case scanPathConfigured = "scanPath.configured"
    case scanPathNoConfigured = "scanPath.noConfigured"

    // Language Names
    case languageJava = "language.java"
    case languageNode = "language.node"
    case languagePython = "language.python"
    case languageGo = "language.go"

    // Custom Language
    case customLanguageTitle = "customLanguage.title"
    case customLanguageAdd = "customLanguage.add"
    case customLanguageEdit = "customLanguage.edit"
    case customLanguageName = "customLanguage.name"
    case customLanguageNamePlaceholder = "customLanguage.namePlaceholder"
    case customLanguageIdentifier = "customLanguage.identifier"
    case customLanguageIdentifierPlaceholder = "customLanguage.identifierPlaceholder"
    case customLanguageIcon = "customLanguage.icon"
    case customLanguageColor = "customLanguage.color"
    case customLanguageScanPaths = "customLanguage.scanPaths"
    case customLanguageAddPath = "customLanguage.addPath"
    case customLanguageEnvVar = "customLanguage.envVar"
    case customLanguageEnvVarPlaceholder = "customLanguage.envVarPlaceholder"
    case customLanguagePreview = "customLanguage.preview"
    case customLanguageDeleteConfirm = "customLanguage.deleteConfirm"
    case customLanguageNoCustomLanguages = "customLanguage.noCustomLanguages"
    case customLanguageAddHint = "customLanguage.addHint"

    // Menu
    case menuTools = "menu.tools"
    case menuRefreshAll = "menu.refreshAll"
    case menuManageDirectoryAccess = "menu.manageDirectoryAccess"
    case menuAbout = "menu.about"
}

// MARK: - Convenience Extensions

extension LocalizationManager {
    /// 快捷访问本地化字符串
    subscript(key: LocalizedKey) -> String {
        localized(key)
    }
}

/// 全局便捷函数，用于获取本地化字符串
func L(_ key: LocalizedKey) -> String {
    LocalizationManager.shared.localized(key)
}

/// 全局便捷函数，用于获取带参数的本地化字符串
func L(_ key: LocalizedKey, _ args: CVarArg...) -> String {
    let format = LocalizationManager.shared.localized(key)
    return String(format: format, arguments: args)
}
