import AppKit
import SwiftUI

// MARK: - Path Info Row

/// 路径信息行组件 - 显示单个扫描路径的详细信息
struct PathInfoRow: View {
    let pathInfo: ScanPathInfo
    let status: PathStatus?
    let onDelete: (() -> Void)?

    @State private var isHovered = false
    @State private var showCopied = false

    init(pathInfo: ScanPathInfo, status: PathStatus? = nil, onDelete: (() -> Void)? = nil) {
        self.pathInfo = pathInfo
        self.status = status
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: DMSpace.s) {
            // 来源标签
            sourceTag

            // 路径信息
            VStack(alignment: .leading, spacing: 2) {
                Text(pathInfo.expandedPath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                // 状态信息
                statusView
            }

            Spacer()

            // 操作按钮
            HStack(spacing: DMSpace.xs) {
                // 复制按钮
                Button {
                    copyPath()
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(showCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered || showCopied ? 1 : 0)

                // Finder 按钮
                if status?.exists == true {
                    Button {
                        revealInFinder()
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1 : 0)
                }

                // 删除按钮（仅自定义路径）
                if !pathInfo.isBuiltIn, let onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1 : 0.5)
                }
            }
        }
        .padding(.horizontal, DMSpace.s)
        .padding(.vertical, DMSpace.xs)
        .background(
            RoundedRectangle(cornerRadius: DMRadius.control)
                .fill(pathInfo.isBuiltIn ? Color.clear : DMColor.controlBackground.opacity(0.5))
        )
        .onHover { hovering in
            withAnimation(DMAnimation.quick) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Subviews

    private var sourceTag: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForSource)
                .font(.system(size: 9, weight: .bold))

            Text(pathInfo.displayName)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(colorForSource)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: DMRadius.xs)
                .fill(colorForSource.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DMRadius.xs)
                .stroke(colorForSource.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusView: some View {
        if let status {
            HStack(spacing: DMSpace.xs) {
                // 存在性状态
                if status.exists {
                    if status.isAccessible {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                            Text(L(.scanPathExists))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                            Text(L(.scanPathNeedsAuth))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Text(L(.scanPathNotExists))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                // 版本数量
                if let versionCount = status.versionCount, versionCount > 0 {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(L(.scanPathVersionCount, versionCount))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        } else {
            HStack(spacing: 2) {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 10, height: 10)
                Text(L(.scanPathScanning))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    private var iconForSource: String {
        switch pathInfo.source {
        case .homebrew: return "mug.fill"
        case .pyenv, .nvm, .gvm, .rbenv, .rvm, .rustup: return "terminal.fill"
        case .asdf: return "cube.fill"
        case .javaHome: return "building.columns.fill"
        case .system: return "desktopcomputer"
        case .custom: return "folder.fill"
        }
    }

    private var colorForSource: Color {
        switch pathInfo.source {
        case .homebrew: return Color(red: 0.95, green: 0.55, blue: 0.15)
        case .pyenv: return .green
        case .nvm: return .green
        case .gvm: return .cyan
        case .asdf: return .purple
        case .rbenv: return .red
        case .rvm: return .red
        case .rustup: return .orange
        case .javaHome: return .orange
        case .system: return .gray
        case .custom: return .blue
        }
    }

    // MARK: - Actions

    private func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pathInfo.expandedPath, forType: .string)
        withAnimation(DMAnimation.quick) {
            showCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(DMAnimation.quick) {
                showCopied = false
            }
        }
    }

    private func revealInFinder() {
        let url = URL(fileURLWithPath: pathInfo.expandedPath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

// MARK: - Preview

#if DEBUG
    struct PathInfoRow_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: DMSpace.s) {
                PathInfoRow(
                    pathInfo: ScanPathInfo(
                        path: "/opt/homebrew/Cellar/python*",
                        source: .homebrew,
                        displayName: "Homebrew (Apple Silicon)"
                    ),
                    status: PathStatus(exists: true, isAccessible: true, versionCount: 3)
                )

                PathInfoRow(
                    pathInfo: ScanPathInfo(
                        path: "~/.pyenv/versions",
                        source: .pyenv
                    ),
                    status: PathStatus(exists: true, isAccessible: true, versionCount: 5)
                )

                PathInfoRow(
                    pathInfo: ScanPathInfo(
                        path: "~/custom/python",
                        source: .custom,
                        isBuiltIn: false
                    ),
                    status: PathStatus(exists: false, isAccessible: false, versionCount: nil),
                    onDelete: {}
                )
            }
            .padding()
            .frame(width: 500)
        }
    }
#endif
