import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var registry: LanguageRegistry
    @StateObject private var dashboardViewModel: DashboardViewModel
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var customLanguageManager = CustomLanguageManager.shared

    enum Route: Hashable {
        case dashboard
        case language(String)
    }

    @State private var selection: Route? = .dashboard
    @State private var showingCustomLanguageEditor = false
    @State private var editingCustomLanguage: CustomLanguageConfig?
    @State private var isSettingsHovered = false

    init(registry: LanguageRegistry) {
        self.registry = registry
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(registry: registry))
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // App Header
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(L(.appName))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(L(.appTagline))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)

                // Section Header - Environments
                sectionHeader(title: L(.navEnvironments))

                // Navigation Items
                ScrollView {
                    VStack(spacing: 4) {
                        // Dashboard
                        SidebarNavItem(
                            title: L(.navDashboard),
                            icon: "square.grid.2x2.fill",
                            color: .blue,
                            isSelected: selection == .dashboard
                        ) {
                            selection = .dashboard
                        }

                        // All Languages (unified list)
                        ForEach(customLanguageManager.customLanguages) { config in
                            SidebarNavItem(
                                title: config.name,
                                icon: config.iconType == .systemSymbol
                                    ? config.iconSymbol : nil,
                                iconImage: config.iconType == .customImage
                                    ? config.iconSymbol : nil,
                                color: config.color,
                                isSelected: selection == .language(config.identifier),
                                isCustom: config.iconType == .systemSymbol
                            ) {
                                selection = .language(config.identifier)
                            }
                            .contextMenu {
                                Button(L(.sharedEdit)) {
                                    editingCustomLanguage = config
                                }
                                Button(L(.sharedDelete), role: .destructive) {
                                    deleteCustomLanguage(config)
                                }
                            }
                        }

                        // Add Custom Language Button
                        addCustomLanguageButton
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
                }

                Spacer()

                Divider()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                settingsButton
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
            }
            .background(
                LinearGradient(
                    colors: [
                        DMColor.windowBackground.opacity(0.8),
                        DMColor.windowBackground.opacity(0.4),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            Group {
                if selection == .dashboard {
                    DashboardView(
                        viewModel: dashboardViewModel,
                        selection: $selection
                    )
                } else if case .language(let languageId) = selection {
                    if let config = customLanguageManager.getConfig(identifier: languageId),
                        let manager = customLanguageManager.getVersionManager(for: languageId)
                    {
                        GenericLanguageView(
                            metadata: config.toMetadata(),
                            manager: AnyLanguageManager(manager)
                        )
                        .id(languageId)
                    } else {
                        EmptyDetailView()
                    }
                } else {
                    EmptyDetailView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 860, idealWidth: 1200, minHeight: 600, idealHeight: 800)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingCustomLanguageEditor) {
            CustomLanguageEditorView { config in
                // 注册新语言到 registry
                if let manager = customLanguageManager.getVersionManager(for: config.identifier) {
                    registry.register(
                        metadata: config.toMetadata(), manager: manager)
                }
            }
        }
        .sheet(item: $editingCustomLanguage) { config in
            CustomLanguageEditorView(config: config) { updatedConfig in
                // 更新 registry
                registry.unregister(id: config.identifier)
                if let manager = customLanguageManager.getVersionManager(
                    for: updatedConfig.identifier)
                {
                    registry.register(
                        metadata: updatedConfig.toMetadata(), manager: manager)
                }
            }
        }
        .onAppear {
            // 注册自定义语言
            customLanguageManager.registerToRegistry(registry)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 12, height: 2)
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary.opacity(0.6))
                .tracking(1.2)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .padding(.horizontal, 14)
    }

    // MARK: - Add Custom Language Button

    private var addCustomLanguageButton: some View {
        Button(action: { showingCustomLanguageEditor = true }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            Color.primary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4]))

                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 32, height: 32)

                Text(L(.customLanguageAdd))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .padding(.top, DMSpace.s)
    }

    // MARK: - Settings Button

    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                settingsButtonContent
            }
            .buttonStyle(.plain)
            .scaleEffect(isSettingsHovered ? 1.02 : 1)
            .animation(.easeOut(duration: 0.15), value: isSettingsHovered)
            .onHover { hovering in
                isSettingsHovered = hovering
            }
        } else {
            Button {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            } label: {
                settingsButtonContent
            }
            .buttonStyle(.plain)
            .scaleEffect(isSettingsHovered ? 1.02 : 1)
            .animation(.easeOut(duration: 0.15), value: isSettingsHovered)
            .onHover { hovering in
                isSettingsHovered = hovering
            }
        }
    }

    private var settingsButtonContent: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(isSettingsHovered ? 0.08 : 0.05),
                                Color.primary.opacity(isSettingsHovered ? 0.04 : 0.02),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color.primary.opacity(isSettingsHovered ? 0.15 : 0.1),
                        style: StrokeStyle(lineWidth: 1, dash: [4])
                    )

                Image(systemName: "gear")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 32, height: 32)

            Text(L(.navSettings))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(isSettingsHovered ? 0.04 : 0))
        )
    }

    // MARK: - Actions

    private func deleteCustomLanguage(_ config: CustomLanguageConfig) {
        registry.unregister(id: config.identifier)
        customLanguageManager.deleteLanguage(id: config.id)

        // 如果当前选中的是被删除的语言，切换到 Dashboard
        if case .language(let id) = selection, id == config.identifier {
            selection = .dashboard
        }
    }
}

// MARK: - Sidebar Navigation Item
private struct SidebarNavItem: View {
    let title: String
    var icon: String? = nil
    var iconImage: String? = nil
    let color: Color
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [color.opacity(0.25), color.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.primary.opacity(isHovered ? 0.08 : 0.05),
                                        Color.primary.opacity(isHovered ? 0.04 : 0.02),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? color.opacity(0.3) : Color.primary.opacity(0.08),
                            lineWidth: 1
                        )

                    Group {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isSelected ? color : .secondary)
                        } else if let iconImage {
                            if isCustom {
                                // 自定义语言使用 SF Symbol
                                Image(systemName: iconImage)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isSelected ? color : .secondary)
                            } else if let url = Bundle.module.url(
                                forResource: iconImage, withExtension: "png"),
                                let nsImage = NSImage(contentsOf: url)
                            {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .saturation(isSelected ? 1.0 : 0.7)
                                    .opacity(isSelected ? 1 : 0.8)
                            }
                        }
                    }
                }
                .frame(width: 32, height: 32)
                .shadow(color: isSelected ? color.opacity(0.25) : .clear, radius: 4, x: 0, y: 2)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [color.opacity(0.12), color.opacity(0.06)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color.primary.opacity(isHovered ? 0.06 : 0),
                                    Color.primary.opacity(isHovered ? 0.03 : 0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? color.opacity(0.2) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .scaleEffect(isHovered && !isSelected ? 1.02 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Empty Detail View
private struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: DMSpace.l) {
            ZStack {
                Circle()
                    .fill(DMGradient.subtle(.secondary))
                    .frame(width: 80, height: 80)
                Image(systemName: "app.dashed")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.secondary.opacity(0.5))
            }

            VStack(spacing: DMSpace.xs) {
                Text(L(.navSelectEnvironment))
                    .font(DMTypography.title3)
                    .foregroundColor(.primary)
                Text(L(.navSelectEnvironmentHint))
                    .font(DMTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DMColor.windowBackground)
    }
}
