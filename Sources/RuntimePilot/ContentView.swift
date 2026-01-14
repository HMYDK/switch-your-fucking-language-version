import AppKit
import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard
    case java
    case node
    case python
    case go

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .java: return "Java JDK"
        case .node: return "Node.js"
        case .python: return "Python"
        case .go: return "Go"
        }
    }

    var iconImage: String {
        switch self {
        case .dashboard: return ""
        case .java: return "java"
        case .node: return "nodejs"
        case .python: return "python"
        case .go: return "go"
        }
    }

    var iconSymbol: String? {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        default: return nil
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .java: return .orange
        case .node: return .green
        case .python: return .indigo
        case .go: return .cyan
        }
    }
}

struct ContentView: View {
    @ObservedObject var registry: LanguageRegistry
    @StateObject private var dashboardViewModel: DashboardViewModel

    enum Route: Hashable {
        case dashboard
        case language(String)
    }

    @State private var selection: Route? = .dashboard

    init(registry: LanguageRegistry) {
        self.registry = registry
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(registry: registry))
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // App Header
                HStack(spacing: DMSpace.s) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .fill(DMGradient.accent(.blue))
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    .frame(width: 28, height: 28)

                    Text("RuntimePilot")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DMSpace.m)
                .padding(.vertical, DMSpace.s)

                Divider()
                    .padding(.horizontal, DMSpace.m)
                    .opacity(0.5)

                // Section Header
                Text("ENVIRONMENTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.7))
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DMSpace.m)
                    .padding(.bottom, DMSpace.xs)
                    .padding(.horizontal, DMSpace.m)

                // Navigation Items (no List, use ScrollView)
                ScrollView {
                    VStack(spacing: 2) {
                        // Dashboard
                        SidebarNavItem(
                            title: "Dashboard",
                            icon: "square.grid.2x2.fill",
                            color: .blue,
                            isSelected: selection == .dashboard
                        ) {
                            selection = .dashboard
                        }

                        // Languages
                        ForEach(registry.allLanguages) { language in
                            let metadata = language.metadata
                            SidebarNavItem(
                                title: metadata.displayName,
                                iconImage: metadata.iconName,
                                color: metadata.color,
                                isSelected: selection == .language(metadata.id)
                            ) {
                                selection = .language(metadata.id)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .background(DMColor.windowBackground.opacity(0.5))
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            Group {
                if selection == .dashboard {
                    DashboardView(
                        viewModel: dashboardViewModel,
                        selection: $selection
                    )
                } else if case .language(let languageId) = selection,
                    let language = registry.getLanguage(for: languageId)
                {
                    GenericLanguageView(
                        metadata: language.metadata,
                        manager: language.manager
                    )
                    .id(languageId)
                } else {
                    EmptyDetailView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 860, idealWidth: 1200, minHeight: 600, idealHeight: 800)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await UpdateChecker.shared.checkForUpdates()
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
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DMSpace.s) {
                // Icon
                Group {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isSelected ? color : .secondary)
                            .frame(width: 20, height: 20)
                    } else if let iconImage {
                        if let url = Bundle.module.url(
                            forResource: iconImage, withExtension: "png"),
                            let nsImage = NSImage(contentsOf: url)
                        {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, DMSpace.s)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isSelected
                            ? color.opacity(0.12)
                            : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
            )
            .overlay(
                HStack(spacing: 0) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(color)
                            .frame(width: 3)
                            .padding(.vertical, 4)
                    }
                    Spacer()
                }
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
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
                Text("Select an Environment")
                    .font(DMTypography.title3)
                    .foregroundColor(.primary)
                Text("Choose a language from the sidebar to manage versions")
                    .font(DMTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DMColor.windowBackground)
    }
}
