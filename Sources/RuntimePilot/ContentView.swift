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
                        Text("RuntimePilot")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("Dev Environment Manager")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)

                // Section Header
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 12, height: 2)
                    Text("ENVIRONMENTS")
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

                // Navigation Items
                ScrollView {
                    VStack(spacing: 4) {
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
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
                }
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
                            if let url = Bundle.module.url(
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
