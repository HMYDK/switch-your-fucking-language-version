import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selection: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar.horizontal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)

                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }

                    Text("Overview of your development environments")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 24)

                // Welcome message for first-time users
                if !viewModel.hasAnyConfigured {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome to DevManager")
                                .font(.callout)
                                .fontWeight(.semibold)
                            Text(
                                "Select a language card below to start managing your development environment"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                }

                // Language Cards Grid
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 320), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.languageStatuses) { status in
                        LanguageStatusCard(
                            status: status,
                            onTap: {
                                withAnimation {
                                    selection = status.id
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)

                // How it works section
                HowItWorksCard()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - How It Works Card

struct HowItWorksCard: View {
    @State private var copied = false

    private let shellConfig = """
        # DevManager - Development Environment Manager
        for env_file in ~/.config/devmanager/*_env.sh; do
            [ -f "$env_file" ] && source "$env_file"
        done
        """

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Section
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Start Guide")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Set up your environment in 3 simple steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)

            // Steps Container
            VStack(alignment: .leading, spacing: 0) {
                // Step 1
                ModernStepView(
                    icon: "hand.tap.fill",
                    color: .blue,
                    title: "Select Version",
                    description: "Click on any language card above to choose the version you want to use.",
                    isLast: false
                )

                // Step 2
                ModernStepView(
                    icon: "terminal.fill",
                    color: .purple,
                    title: "Configure Shell",
                    description: "Add the following script to your shell configuration file (e.g., ~/.zshrc):",
                    isLast: false
                ) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: 0) {
                            Text(shellConfig)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .padding(16)

                            Spacer()

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(shellConfig, forType: .string)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    copied = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        copied = false
                                    }
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(copied ? Color.green : Color.white.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(copied ? .white : .white.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(12)
                            .help("Copy to clipboard")
                        }
                    }
                    .background(Color(NSColor.windowFrameTextColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }

                // Step 3
                ModernStepView(
                    icon: "bolt.fill",
                    color: .orange,
                    title: "Activate",
                    description: "Restart your terminal or run `source ~/.zshrc` to apply the changes.",
                    isLast: true
                )
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

struct ModernStepView<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let isLast: Bool
    let content: Content

    init(
        icon: String,
        color: Color,
        title: String,
        description: String,
        isLast: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.color = color
        self.title = title
        self.description = description
        self.isLast = isLast
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Icon Column
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .frame(width: 36)

            // Content Column
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                content
                    .padding(.top, 8)

                Spacer().frame(height: isLast ? 0 : 32)
            }
        }
    }
}

extension ModernStepView where Content == EmptyView {
    init(icon: String, color: Color, title: String, description: String, isLast: Bool = false) {
        self.init(
            icon: icon,
            color: color,
            title: title,
            description: description,
            isLast: isLast
        ) {
            EmptyView()
        }
    }
}

// MARK: - Language Status Card

struct LanguageStatusCard: View {
    let status: LanguageStatus
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Top section with icon and language name
                HStack(spacing: 16) {
                    // Language icon
                    ZStack {
                        Circle()
                            .fill(
                                status.isConfigured
                                    ? status.color.opacity(0.15)
                                    : Color.gray.opacity(0.1)
                            )
                            .frame(width: 64, height: 64)

                        LanguageIconView(
                            imageName: status.iconName,
                            size: 48
                        )
                        .opacity(status.isConfigured ? 1.0 : 0.5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // Language name
                        Text(status.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        // Status indicator
                        if status.isConfigured {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(status.color)
                                Text("Configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("Not configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Arrow indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }

                Divider()

                // Version information
                if status.isConfigured, let version = status.activeVersion {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current Version")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Text(version)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if let source = status.activeSource {
                                SourceTagView(source: source)
                            }
                        }

                        // Installed count
                        if status.installedCount > 0 {
                            Text(
                                "\(status.installedCount) version\(status.installedCount == 1 ? "" : "s") installed"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // Not configured state
                    VStack(alignment: .leading, spacing: 8) {
                        if status.installedCount > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)

                                Text("No version selected")
                                    .font(.callout)
                                    .foregroundColor(.primary)
                            }

                            Text(
                                "\(status.installedCount) version\(status.installedCount == 1 ? "" : "s") available"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)

                                Text("No versions installed")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }

                            Text("Click to install and configure")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        status.isConfigured
                            ? status.color.opacity(0.5)
                            : Color.gray.opacity(0.2),
                        lineWidth: status.isConfigured ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.08 : 0),
                radius: isHovered ? 8 : 0,
                x: 0,
                y: isHovered ? 4 : 0
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.25)) {
                isHovered = hovering
            }
        }
    }
}
