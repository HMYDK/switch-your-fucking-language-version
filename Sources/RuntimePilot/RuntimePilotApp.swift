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
    @StateObject private var javaManager = JavaManager()
    @StateObject private var nodeManager = NodeManager()
    @StateObject private var pythonManager = PythonManager()
    @StateObject private var goManager = GoManager()
    @StateObject private var registry = LanguageRegistry()
    @StateObject private var directoryAccessManager = DirectoryAccessManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var showOnboarding = false

    init() {
        // 注册所有语言
        setupRegistry()
    }

    private func setupRegistry() {
        // 注意:这里在init中调用,需要延迟到body中执行
    }

    var body: some Scene {
        WindowGroup {
            ContentView(registry: registry)
                .onAppear {
                    // 在视图出现时注册语言
                    registry.register(metadata: .java, manager: javaManager)
                    registry.register(metadata: .node, manager: nodeManager)
                    registry.register(metadata: .python, manager: pythonManager)
                    registry.register(metadata: .go, manager: goManager)

                    // 检查是否需要显示引导
                    if directoryAccessManager.needsOnboarding {
                        showOnboarding = true
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(
                        accessManager: directoryAccessManager,
                        isPresented: $showOnboarding
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
                    for language in registry.allLanguages {
                        language.manager.refresh()
                    }
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
