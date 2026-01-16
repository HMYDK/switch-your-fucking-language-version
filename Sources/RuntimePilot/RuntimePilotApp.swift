import SwiftUI

// MARK: - App Version

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

@main
struct RuntimePilotApp: App {
    @StateObject private var registry = LanguageRegistry()
    @StateObject private var directoryAccessManager = DirectoryAccessManager.shared
    @ObservedObject private var customLanguageManager = CustomLanguageManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView(registry: registry)
                .onAppear {
                    // 执行数据迁移（从旧版本内置语言迁移到新版本自定义语言）
                    MigrationManager.shared.migrateIfNeeded()
                    
                    // 注册所有自定义语言到 Registry
                    customLanguageManager.registerToRegistry(registry)

                    // 检查是否需要显示语言选择引导
                    if MigrationManager.shared.needsOnboarding {
                        showOnboarding = true
                    } else if directoryAccessManager.needsOnboarding {
                        showOnboarding = true
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(
                        accessManager: directoryAccessManager,
                        isPresented: $showOnboarding,
                        registry: registry
                    )
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.automatic)

        Settings {
            SettingsView()
        }

        .commands {
            SidebarCommands()

            // About 菜单
            CommandGroup(replacing: .appInfo) {
                Button(L(.menuAbout)) {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: L(.appName),
                            .applicationVersion: AppInfo.version,
                            .credits: NSAttributedString(string: L(.appTagline)),
                        ]
                    )
                }
            }

            // 移除不需要的菜单项
            CommandGroup(replacing: .newItem) {}

            // Tools 菜单
            CommandMenu(L(.menuTools)) {
                Button(L(.menuRefreshAll)) {
                    // 刷新所有已注册的语言
                    customLanguageManager.refreshAll()
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button(L(.menuManageDirectoryAccess)) {
                    showOnboarding = true
                }
            }
        }
    }
}
