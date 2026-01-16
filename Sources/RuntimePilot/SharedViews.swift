import AppKit
import SwiftUI

// MARK: - Uninstall Guide View

/// 卸载引导弹窗 - 显示卸载命令供用户复制执行
struct UninstallGuideView: View {
    let version: String
    let source: String
    let path: String
    let onDismiss: () -> Void

    @State private var showCopied = false
    @State private var isCopyHovered = false
    @State private var isTerminalHovered = false

    private var uninstallInfo: (command: String?, hint: LocalizedKey, sourceName: String) {
        let lowercaseSource = source.lowercased()
        let lowercasePath = path.lowercased()

        // Homebrew
        if lowercaseSource.contains("homebrew") || lowercasePath.contains("cellar") {
            // 从路径提取 formula 名称
            var formula = ""
            if let range = path.range(of: "/Cellar/") {
                let afterCellar = String(path[range.upperBound...])
                formula = afterCellar.components(separatedBy: "/").first ?? ""
            }
            if formula.isEmpty {
                formula = "package-name"
            }
            return ("brew uninstall \(formula)", .uninstallGuideHomebrewHint, "Homebrew")
        }

        // NVM
        if lowercaseSource.contains("nvm") || lowercasePath.contains(".nvm") {
            return ("nvm uninstall \(version)", .uninstallGuideNvmHint, "NVM")
        }

        // pyenv
        if lowercaseSource.contains("pyenv") || lowercasePath.contains(".pyenv") {
            return ("pyenv uninstall \(version)", .uninstallGuidePyenvHint, "pyenv")
        }

        // GVM
        if lowercaseSource.contains("gvm") || lowercasePath.contains(".gvm") {
            return ("gvm uninstall go\(version)", .uninstallGuideGvmHint, "GVM")
        }

        // asdf
        if lowercaseSource.contains("asdf") || lowercasePath.contains(".asdf") {
            // 尝试从路径推断插件名
            var plugin = "plugin"
            if let range = path.range(of: ".asdf/installs/") {
                let afterInstalls = String(path[range.upperBound...])
                plugin = afterInstalls.components(separatedBy: "/").first ?? "plugin"
            }
            return ("asdf uninstall \(plugin) \(version)", .uninstallGuideAsdfHint, "asdf")
        }

        // rbenv
        if lowercaseSource.contains("rbenv") || lowercasePath.contains(".rbenv") {
            return ("rbenv uninstall \(version)", .uninstallGuideRbenvHint, "rbenv")
        }

        // RVM
        if lowercaseSource.contains("rvm") || lowercasePath.contains(".rvm") {
            return ("rvm remove \(version)", .uninstallGuideRvmHint, "RVM")
        }

        // rustup
        if lowercaseSource.contains("rustup") || lowercasePath.contains(".rustup") {
            return ("rustup toolchain remove \(version)", .uninstallGuideRustupHint, "rustup")
        }

        // System JDK or unknown - manual removal
        return (nil, .uninstallGuideManualHint, source)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L(.uninstallGuideTitle, version))
                        .font(.system(size: 16, weight: .bold))
                    Text(L(.uninstallGuideSubtitle, uninstallInfo.sourceName))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 16) {
                if let command = uninstallInfo.command {
                    // Command box
                    HStack(spacing: 8) {
                        Image(systemName: "terminal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)

                        Text(command)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(command, forType: .string)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCopied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showCopied = false
                                }
                            }
                        } label: {
                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(showCopied ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                    // Hint
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(L(uninstallInfo.hint))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Manual removal hint
                    HStack(spacing: 10) {
                        Image(systemName: "folder.badge.minus")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L(uninstallInfo.hint))
                                .font(.system(size: 13))
                                .foregroundColor(.primary)

                            Text(path)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                }

                // Refresh reminder
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                    Text(L(.uninstallGuideRefreshAfter))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)

            Divider()

            // Actions
            HStack(spacing: 12) {
                Spacer()

                if uninstallInfo.command != nil {
                    Button {
                        if let command = uninstallInfo.command {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(command, forType: .string)
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCopied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .semibold))
                            Text(showCopied ? L(.sharedSuccess) : L(.uninstallGuideCopyCommand))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    showCopied
                                        ? Color.green.opacity(0.15)
                                        : Color.primary.opacity(isCopyHovered ? 0.1 : 0.06))
                        )
                        .foregroundColor(showCopied ? .green : .primary)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isCopyHovered ? 1.02 : 1)
                    .animation(.easeOut(duration: 0.15), value: isCopyHovered)
                    .onHover { hovering in
                        isCopyHovered = hovering
                    }

                    Button {
                        // Open Terminal app
                        NSWorkspace.shared.open(
                            URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "terminal")
                                .font(.system(size: 12, weight: .semibold))
                            Text(L(.uninstallGuideOpenTerminal))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isTerminalHovered ? 1.02 : 1)
                    .animation(.easeOut(duration: 0.15), value: isTerminalHovered)
                    .onHover { hovering in
                        isTerminalHovered = hovering
                    }
                } else {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                                .font(.system(size: 12, weight: .semibold))
                            Text(L(.sharedRevealInFinder))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isTerminalHovered ? 1.02 : 1)
                    .animation(.easeOut(duration: 0.15), value: isTerminalHovered)
                    .onHover { hovering in
                        isTerminalHovered = hovering
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 440)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Source Tag View

struct SourceTagView: View {
    let source: String

    private var isHomebrew: Bool {
        source.lowercased().contains("homebrew")
    }

    var body: some View {
        if isHomebrew {
            HStack(spacing: 4) {
                Image(systemName: "mug.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Homebrew")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.15))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: DMRadius.control)
                    .fill(Color(red: 0.95, green: 0.55, blue: 0.15).opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DMRadius.control)
                    .stroke(Color(red: 0.95, green: 0.55, blue: 0.15).opacity(0.25), lineWidth: 1)
            )
        } else {
            Text(source)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Language Icon View

struct LanguageIconView: View {
    let imageName: String
    let size: CGFloat

    var body: some View {
        if let url = Bundle.module.url(forResource: imageName, withExtension: "png"),
            let nsImage = NSImage(contentsOf: url)
        {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "questionmark.circle")
                .font(.system(size: size * 0.8))
                .foregroundColor(.secondary)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Modern Version Card

struct ModernVersionCard: View {
    let version: String
    let source: String
    let path: String
    let isActive: Bool
    let iconImage: String
    let color: Color
    let onUse: () -> Void
    let onOpenFinder: () -> Void

    @State private var isHovered = false
    @State private var showCopied = false
    @State private var showUninstallGuide = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? color.opacity(0.15) : Color.gray.opacity(0.08))
                        .frame(width: 44, height: 44)

                    LanguageIconView(imageName: iconImage, size: 24)
                }

                // Version & Source
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(version)
                            .font(.system(size: 15, weight: .bold, design: .rounded))

                        if isActive {
                            Text("CURRENT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color)
                                )
                        }
                    }

                    SourceTagView(source: source)
                }

                Spacer(minLength: 8)

                // Action area
                if isActive {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(color)

                        Button(action: { showUninstallGuide = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovered ? 1 : 0)
                    }
                } else {
                    HStack(spacing: 6) {
                        Button(action: onUse) {
                            Text("Use")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(color)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: onOpenFinder) {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: { showUninstallGuide = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .opacity(isHovered ? 1 : 0.6)
                }
            }
            .padding(12)

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 12)

            // Path section
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Text(path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 4)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                    withAnimation { showCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation { showCopied = false }
                    }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(showCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered || showCopied ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? color.opacity(0.04) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive
                        ? color.opacity(0.3)
                        : (isHovered ? color.opacity(0.2) : Color.primary.opacity(0.08)),
                    lineWidth: isActive ? 1.5 : 1
                )
        )
        .shadow(
            color: Color.black.opacity(isHovered ? 0.08 : 0.04),
            radius: isHovered ? 12 : 6,
            x: 0,
            y: isHovered ? 4 : 2
        )
        .scaleEffect(isHovered && !isActive ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Use This Version") { onUse() }
                .disabled(isActive)
            Divider()
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(path, forType: .string)
            }
            Button("Reveal in Finder") { onOpenFinder() }
            Divider()
            Button(L(.uninstallGuideUninstall)) { showUninstallGuide = true }
        }
        .sheet(isPresented: $showUninstallGuide) {
            UninstallGuideView(
                version: version,
                source: source,
                path: path,
                onDismiss: { showUninstallGuide = false }
            )
        }
    }
}

// MARK: - Config Hint View

struct ConfigHintView: View {
    let filename: String
    @State private var showCopied = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: DMSpace.s) {
            HStack(spacing: DMSpace.xs) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                Text("Setup Required")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
            }

            HStack(spacing: DMSpace.s) {
                Text("source ~/.config/devmanager/\(filename)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, DMSpace.m)
                    .padding(.vertical, DMSpace.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .fill(DMColor.textBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .stroke(DMColor.separator.opacity(0.5), lineWidth: 1)
                    )
                    .textSelection(.enabled)

                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(
                        "source ~/.config/devmanager/\(filename)", forType: .string)
                    withAnimation(DMAnimation.quick) {
                        showCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(DMAnimation.quick) {
                            showCopied = false
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .fill(
                                showCopied ? Color.green.opacity(0.15) : Color.primary.opacity(0.06)
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(showCopied ? .green : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(isHovered ? 1.05 : 1)
                .animation(DMAnimation.quick, value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
            }
        }
        .padding(DMSpace.m)
        .background(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .fill(Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Modern Empty State

struct ModernEmptyState: View {
    let iconImage: String
    let title: String
    let message: String
    let color: Color
    let onRefresh: () -> Void
    var onInstallNew: (() -> Void)? = nil

    @State private var isRefreshHovered = false
    @State private var isInstallHovered = false

    var body: some View {
        VStack(spacing: DMSpace.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(DMGradient.subtle(color))
                    .frame(width: 100, height: 100)

                LanguageIconView(imageName: iconImage, size: 48)
                    .opacity(0.6)
            }

            // Text
            VStack(spacing: DMSpace.xs) {
                Text(title)
                    .font(DMTypography.title3)
                    .foregroundColor(.primary)

                Text(message)
                    .font(DMTypography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            // Actions
            VStack(spacing: DMSpace.s) {
                Button(action: onRefresh) {
                    HStack(spacing: DMSpace.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Refresh")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, DMSpace.xl)
                    .padding(.vertical, DMSpace.s)
                    .background(
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .fill(Color.primary.opacity(isRefreshHovered ? 0.1 : 0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .scaleEffect(isRefreshHovered ? 1.02 : 1)
                .animation(DMAnimation.quick, value: isRefreshHovered)
                .onHover { hovering in
                    isRefreshHovered = hovering
                }

                if let installAction = onInstallNew {
                    Button(action: installAction) {
                        HStack(spacing: DMSpace.xs) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Install New Version")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, DMSpace.xl)
                        .padding(.vertical, DMSpace.s)
                        .background(
                            RoundedRectangle(cornerRadius: DMRadius.control)
                                .fill(color)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isInstallHovered ? 1.02 : 1)
                    .shadow(
                        color: color.opacity(isInstallHovered ? 0.4 : 0.2),
                        radius: isInstallHovered ? 12 : 6, x: 0, y: isInstallHovered ? 6 : 3
                    )
                    .animation(DMAnimation.quick, value: isInstallHovered)
                    .onHover { hovering in
                        isInstallHovered = hovering
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DMSpace.xxxl)
    }
}

// MARK: - Version Action Bar

struct VersionActionBar: View {
    let installedCount: Int
    let color: Color

    var body: some View {
        HStack(spacing: DMSpace.m) {
            // Stats
            HStack(spacing: DMSpace.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DMRadius.xs)
                        .fill(color.opacity(0.12))
                        .frame(width: 24, height: 24)
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color)
                }

                Text("\(installedCount) version\(installedCount == 1 ? "" : "s") installed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()

            // Hint
            HStack(spacing: DMSpace.xs) {
                Image(systemName: "terminal")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Use Homebrew or version managers to install")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, DMSpace.xl)
        .padding(.vertical, DMSpace.m)
        .background(DMColor.controlBackground.opacity(0.8))
        .overlay(
            Rectangle()
                .fill(DMColor.separator.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
