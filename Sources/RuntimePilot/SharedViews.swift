import AppKit
import SwiftUI

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
            .fixedSize()
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
                .lineLimit(1)
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
                            .lineLimit(1)

                        if isActive {
                            Text("CURRENT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .fixedSize()
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(color)
                } else {
                    HStack(spacing: 6) {
                        Button(action: onUse) {
                            Text("Use")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .fixedSize()
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
                Text("source ~/.config/runtimepilot/\(filename)")
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
                        "source ~/.config/runtimepilot/\(filename)", forType: .string)
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

    @State private var isRefreshHovered = false

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
