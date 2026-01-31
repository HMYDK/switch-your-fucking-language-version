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
    @StateObject private var registry: LanguageRegistry
    @StateObject private var directoryAccessManager = DirectoryAccessManager.shared
    @ObservedObject private var customLanguageManager = CustomLanguageManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var showOnboarding = false

    init() {
        // 创建 registry 并立即注册所有语言（在 ContentView 创建之前）
        let registry = LanguageRegistry()
        CustomLanguageManager.shared.registerToRegistry(registry)
        _registry = StateObject(wrappedValue: registry)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(registry: registry)
                .onAppear {
                    // 检查是否需要显示引导
                    if directoryAccessManager.needsOnboarding {
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
