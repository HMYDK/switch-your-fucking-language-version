import AppKit
import SwiftUI

// MARK: - Spacing System
enum DMSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Radius System
enum DMRadius {
    static let xs: CGFloat = 4
    static let control: CGFloat = 8
    static let card: CGFloat = 12
    static let container: CGFloat = 16
    static let large: CGFloat = 20
}

// MARK: - Typography System
enum DMTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title
    static let title2 = Font.title2.weight(.bold)
    static let title3 = Font.title3.weight(.semibold)
    static let section = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let caption2 = Font.caption2
    static let monospaceCaption = Font.system(.caption, design: .monospaced)
    static let monospaceSm = Font.system(size: 11, weight: .medium, design: .monospaced)
}

// MARK: - Color System
enum DMColor {
    static let windowBackground = Color(NSColor.windowBackgroundColor)
    static let controlBackground = Color(NSColor.controlBackgroundColor)
    static let textBackground = Color(NSColor.textBackgroundColor)
    static let separator = Color(NSColor.separatorColor)
    static let tertiaryLabel = Color(NSColor.tertiaryLabelColor)

    // Semantic colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
}

// MARK: - Gradient Presets
enum DMGradient {
    static func accent(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.15), color.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func subtle(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.08), color.opacity(0.02)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func glass() -> LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.1), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func hero(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.2), color.opacity(0.08), color.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shadow Presets
enum DMShadow {
    static func soft(color: Color = .black) -> some View {
        EmptyView()
            .shadow(color: color.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    static func medium(color: Color = .black) -> some View {
        EmptyView()
            .shadow(color: color.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    static func glow(color: Color) -> some View {
        EmptyView()
            .shadow(color: color.opacity(0.3), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Animation Presets
enum DMAnimation {
    static let quick = Animation.easeOut(duration: 0.15)
    static let smooth = Animation.easeInOut(duration: 0.25)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
}

// MARK: - Card Component
struct DMCard<Content: View>: View {
    let accent: Color?
    let isEmphasized: Bool
    let isInteractive: Bool
    let content: Content

    @State private var isHovered = false

    init(
        accent: Color? = nil,
        isEmphasized: Bool = false,
        isInteractive: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.accent = accent
        self.isEmphasized = isEmphasized
        self.isInteractive = isInteractive
        self.content = content()
    }

    var body: some View {
        content
            .padding(DMSpace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(border)
            .shadow(
                color: shadowColor,
                radius: isHovered ? 16 : 8,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isHovered && isInteractive ? 1.008 : 1)
            .animation(DMAnimation.smooth, value: isHovered)
            .onHover { hovering in
                if isInteractive {
                    isHovered = hovering
                }
            }
    }

    @ViewBuilder
    private var background: some View {
        if let accent, isEmphasized {
            RoundedRectangle(cornerRadius: DMRadius.container)
                .fill(DMGradient.hero(accent))
                .background(
                    RoundedRectangle(cornerRadius: DMRadius.container)
                        .fill(DMColor.controlBackground)
                )
        } else {
            RoundedRectangle(cornerRadius: DMRadius.container)
                .fill(DMColor.controlBackground)
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: DMRadius.container)
            .stroke(borderColor, lineWidth: isEmphasized ? 1.5 : 1)
    }

    private var borderColor: Color {
        if let accent, isEmphasized {
            return accent.opacity(isHovered ? 0.5 : 0.3)
        }
        return DMColor.separator.opacity(isHovered ? 0.5 : 0.3)
    }

    private var shadowColor: Color {
        if let accent, isEmphasized {
            return accent.opacity(isHovered ? 0.15 : 0.08)
        }
        return Color.black.opacity(isHovered ? 0.1 : 0.05)
    }
}

// MARK: - Section Component
struct DMSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color?
    let trailing: AnyView?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color? = nil,
        trailing: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DMSpace.m) {
            HStack(alignment: .center, spacing: DMSpace.s) {
                if let icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .fill((iconColor ?? .secondary).opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(iconColor ?? .secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DMTypography.section)
                    if let subtitle {
                        Text(subtitle)
                            .font(DMTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let trailing {
                    trailing
                }
            }

            content
        }
    }
}

// MARK: - Badge Component
struct DMBadge: View {
    let text: String
    let accent: Color
    let style: BadgeStyle

    enum BadgeStyle {
        case filled
        case outlined
        case subtle
    }

    init(text: String, accent: Color, style: BadgeStyle = .subtle) {
        self.text = text
        self.accent = accent
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .overlay(border)
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .outlined, .subtle:
            return accent
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .filled:
            RoundedRectangle(cornerRadius: DMRadius.xs)
                .fill(accent)
        case .outlined:
            RoundedRectangle(cornerRadius: DMRadius.xs)
                .fill(Color.clear)
        case .subtle:
            RoundedRectangle(cornerRadius: DMRadius.xs)
                .fill(accent.opacity(0.12))
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .filled:
            EmptyView()
        case .outlined:
            RoundedRectangle(cornerRadius: DMRadius.xs)
                .stroke(accent.opacity(0.5), lineWidth: 1)
        case .subtle:
            RoundedRectangle(cornerRadius: DMRadius.xs)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Key Value Row
struct DMKeyValueRow: View {
    let key: String
    let value: String
    let isMonospaced: Bool
    let onCopy: (() -> Void)?

    @State private var justCopied = false
    @State private var isHovered = false

    init(key: String, value: String, isMonospaced: Bool = false, onCopy: (() -> Void)? = nil) {
        self.key = key
        self.value = value
        self.isMonospaced = isMonospaced
        self.onCopy = onCopy
    }

    var body: some View {
        HStack(spacing: DMSpace.xs) {
            Text(key)
                .font(DMTypography.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(isMonospaced ? DMTypography.monospaceSm : DMTypography.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Spacer()

            if let onCopy {
                Button {
                    onCopy()
                    withAnimation(DMAnimation.quick) {
                        justCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(DMAnimation.quick) {
                            justCopied = false
                        }
                    }
                } label: {
                    Image(systemName: justCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(justCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered || justCopied ? 1 : 0)
                .help("Copy")
            }
        }
        .padding(.vertical, DMSpace.xxs)
        .onHover { hovering in
            withAnimation(DMAnimation.quick) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Code Block
struct DMCodeBlock: View {
    let text: String
    let onCopy: (() -> Void)?

    @State private var copied = false
    @State private var isHovered = false

    init(text: String, onCopy: (() -> Void)? = nil) {
        self.text = text
        self.onCopy = onCopy
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.9))
                .lineSpacing(4)
                .textSelection(.enabled)
                .padding(DMSpace.m)

            Spacer(minLength: 0)

            if let onCopy {
                Button {
                    onCopy()
                    withAnimation(DMAnimation.quick) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(DMAnimation.quick) {
                            copied = false
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: DMRadius.control)
                            .fill(
                                (copied ? Color.green : Color.primary).opacity(copied ? 0.15 : 0.06)
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(copied ? .green : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(DMSpace.s)
                .scaleEffect(isHovered ? 1.05 : 1)
                .animation(DMAnimation.quick, value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
                .help("Copy")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .fill(DMColor.textBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .stroke(DMColor.separator.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Icon Badge (New)
struct DMIconBadge: View {
    let icon: String
    let color: Color
    let size: CGFloat

    init(icon: String, color: Color, size: CGFloat = 40) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3)
                .fill(DMGradient.accent(color))
            RoundedRectangle(cornerRadius: size * 0.3)
                .stroke(color.opacity(0.2), lineWidth: 1)
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Stat Card (New)
struct DMStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: DMSpace.m) {
            DMIconBadge(icon: icon, color: color, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(DMTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DMSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .fill(DMColor.controlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .stroke(DMColor.separator.opacity(0.3), lineWidth: 1)
        )
    }
}
