import AppKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selection: ContentView.Route?
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var isQuickStartExpanded: Bool

    init(viewModel: DashboardViewModel, selection: Binding<ContentView.Route?>) {
        self.viewModel = viewModel
        self._selection = selection
        _isQuickStartExpanded = State(initialValue: !viewModel.hasAnyConfigured)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DMSpace.xxl) {
                // Hero Header
                heroHeader

                // Stats Overview (when configured)
                if viewModel.hasAnyConfigured {
                    statsOverview
                }

                // Welcome Card (when not configured)
                if !viewModel.hasAnyConfigured {
                    welcomeCard
                }

                // Environments Section
                DMSection(
                    title: L(.dashboardEnvironments),
                    subtitle: L(.dashboardSelectLanguage),
                    icon: "square.stack.3d.up.fill",
                    iconColor: .purple
                ) {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 260, maximum: 320), spacing: DMSpace.m)
                        ],
                        spacing: DMSpace.m
                    ) {
                        ForEach(sortedStatuses) { status in
                            EnvironmentCard(status: status) {
                                withAnimation(DMAnimation.spring) {
                                    selection = .language(status.id)
                                }
                            }
                        }
                    }
                }

                // Quick Start Section
                DMSection(
                    title: L(.dashboardQuickStart),
                    subtitle: L(.dashboardShellSetup),
                    icon: "bolt.fill",
                    iconColor: .orange
                ) {
                    quickStartCard
                }

                Spacer(minLength: DMSpace.xxl)
            }
            .padding(.horizontal, DMSpace.xxl)
            .padding(.vertical, DMSpace.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DMColor.windowBackground)
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        HStack(alignment: .center, spacing: DMSpace.m) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: DMRadius.container)
                    .fill(DMGradient.hero(.blue))
                RoundedRectangle(cornerRadius: DMRadius.container)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.blue)
            }
            .frame(width: 52, height: 52)
            .shadow(color: .blue.opacity(0.2), radius: 12, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(L(.dashboardTitle))
                    .font(DMTypography.title2)
                Text(L(.dashboardSubtitle))
                    .font(DMTypography.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Stats Overview
    private var statsOverview: some View {
        HStack(spacing: DMSpace.m) {
            DMStatCard(
                title: L(.dashboardActive),
                value: "\(viewModel.languageStatuses.filter { $0.isConfigured }.count)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            DMStatCard(
                title: L(.dashboardInstalled),
                value: "\(viewModel.languageStatuses.reduce(0) { $0 + $1.installedCount })",
                icon: "square.stack.3d.up.fill",
                color: .blue
            )

            DMStatCard(
                title: L(.dashboardLanguages),
                value: "\(viewModel.languageStatuses.count)",
                icon: "globe",
                color: .purple
            )
        }
    }

    // MARK: - Welcome Card
    private var welcomeCard: some View {
        DMCard(accent: .blue, isEmphasized: true) {
            HStack(alignment: .top, spacing: DMSpace.m) {
                ZStack {
                    Circle()
                        .fill(DMGradient.accent(.blue))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L(.dashboardWelcome))
                        .font(DMTypography.section)
                    Text("Pick a language below, then select or install a version to get started.")
                        .font(DMTypography.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }

    // MARK: - Quick Start Card
    private var quickStartCard: some View {
        DMCard(isInteractive: false) {
            DisclosureGroup(isExpanded: $isQuickStartExpanded) {
                VStack(alignment: .leading, spacing: DMSpace.l) {
                    QuickStartStep(
                        number: 1,
                        symbol: "hand.tap.fill",
                        accent: .blue,
                        title: "Select a version",
                        detail: "Open a language on the left and press Use on the version you want."
                    )

                    QuickStartStep(
                        number: 2,
                        symbol: "terminal.fill",
                        accent: .purple,
                        title: "Configure your shell",
                        detail: "Add the snippet below to your shell config file (e.g. ~/.zshrc)."
                    ) {
                        DMCodeBlock(
                            text: shellConfig,
                            onCopy: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(shellConfig, forType: .string)
                            }
                        )
                    }

                    QuickStartStep(
                        number: 3,
                        symbol: "bolt.fill",
                        accent: .orange,
                        title: "Activate",
                        detail: "Restart your terminal or run source ~/.zshrc."
                    )
                }
                .padding(.top, DMSpace.m)
            } label: {
                HStack(spacing: DMSpace.s) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Set up in 3 steps")
                        .font(DMTypography.section)
                    Spacer()
                    DMBadge(text: "~2 min", accent: .secondary, style: .outlined)
                }
            }
            .tint(.primary)
        }
    }

    private var sortedStatuses: [LanguageStatus] {
        viewModel.languageStatuses.sorted { lhs, rhs in
            if lhs.isConfigured != rhs.isConfigured {
                return lhs.isConfigured && !rhs.isConfigured
            }
            if lhs.installedCount != rhs.installedCount {
                return lhs.installedCount > rhs.installedCount
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
                == .orderedAscending
        }
    }

    private let shellConfig = """
        # RuntimePilot - Development Environment Manager
        for env_file in ~/.config/devmanager/*_env.sh; do
            [ -f "$env_file" ] && source "$env_file"
        done
        """
}

// MARK: - Quick Start Step
private struct QuickStartStep<Content: View>: View {
    let number: Int
    let symbol: String
    let accent: Color
    let title: String
    let detail: String
    let content: Content

    init(
        number: Int,
        symbol: String,
        accent: Color,
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) {
        self.number = number
        self.symbol = symbol
        self.accent = accent
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: DMSpace.m) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(DMGradient.accent(accent))
                    .frame(width: 40, height: 40)
                Circle()
                    .stroke(accent.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 40, height: 40)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: DMSpace.xs) {
                HStack(spacing: DMSpace.xs) {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(title)
                        .font(DMTypography.section)
                }

                Text(detail)
                    .font(DMTypography.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                content
            }
        }
    }
}

extension QuickStartStep where Content == EmptyView {
    init(number: Int, symbol: String, accent: Color, title: String, detail: String) {
        self.init(number: number, symbol: symbol, accent: accent, title: title, detail: detail) {
            EmptyView()
        }
    }
}

// MARK: - Environment Card
private struct EnvironmentCard: View {
    let status: LanguageStatus
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: DMSpace.s) {
                    // Language Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: DMRadius.card)
                            .fill(
                                status.isConfigured
                                    ? DMGradient.accent(status.color) : DMGradient.subtle(.gray)
                            )
                            .frame(width: 44, height: 44)

                        LanguageIconView(imageName: status.iconName, size: 24)
                            .opacity(status.installedCount == 0 ? 0.5 : 1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        if let version = status.activeVersion {
                            Text("v\(version)")
                                .font(DMTypography.monospaceSm)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(status.installedCount > 0 ? "Not configured" : "Not installed")
                                .font(DMTypography.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    // Status Badge
                    statusBadge
                }
                .padding(DMSpace.m)

                Divider()
                    .padding(.horizontal, DMSpace.m)

                // Details
                HStack(spacing: DMSpace.xl) {
                    DetailItem(
                        label: "Source",
                        value: status.activeSource ?? "—",
                        isHighlighted: status.activeSource?.contains("Homebrew") ?? false
                    )

                    DetailItem(
                        label: "Installed",
                        value: "\(status.installedCount)",
                        isHighlighted: false
                    )
                }
                .padding(DMSpace.m)
            }
            .background(
                RoundedRectangle(cornerRadius: DMRadius.container)
                    .fill(DMColor.controlBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DMRadius.container)
                    .stroke(
                        isHovered ? status.color.opacity(0.5) : Color.primary.opacity(0.08),
                        lineWidth: isHovered ? 2 : 1
                    )
            )
            .shadow(
                color: isHovered ? status.color.opacity(0.15) : Color.black.opacity(0.05),
                radius: isHovered ? 16 : 8,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isHovered ? 1.015 : 1.0)
            .animation(DMAnimation.smooth, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if status.isConfigured {
            DMBadge(text: "Active", accent: status.color, style: .filled)
        } else if status.installedCount > 0 {
            DMBadge(text: "Select", accent: .orange, style: .subtle)
        } else {
            DMBadge(text: "Install", accent: .secondary, style: .outlined)
        }
    }
}

// MARK: - Detail Item
private struct DetailItem: View {
    let label: String
    let value: String
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            if isHighlighted {
                HStack(spacing: 4) {
                    Image(systemName: "mug.fill")
                        .font(.system(size: 10))
                    Text("Homebrew")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color(red: 0.95, green: 0.55, blue: 0.15))
            } else {
                Text(value)
                    .font(
                        .system(
                            size: 12, weight: .medium, design: value == "—" ? .default : .monospaced
                        )
                    )
                    .foregroundStyle(value == "—" ? .tertiary : .secondary)
            }
        }
    }
}
