import AppKit
import SwiftUI

// MARK: - Scan Path Settings View

/// 扫描路径设置视图 - 管理各语言的扫描路径配置
struct ScanPathSettingsView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var configManager = ScanPathConfigManager.shared

    @State private var expandedLanguages: Set<String> = []

    private let languages: [LanguageMetadata] = [
        .java, .python, .go, .node,
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DMSpace.l) {
                // 说明文本
                descriptionSection

                // 语言配置列表
                ForEach(languages) { language in
                    LanguagePathConfigCard(
                        language: language,
                        isExpanded: expandedLanguages.contains(language.id),
                        onToggle: {
                            withAnimation(DMAnimation.smooth) {
                                if expandedLanguages.contains(language.id) {
                                    expandedLanguages.remove(language.id)
                                } else {
                                    expandedLanguages.insert(language.id)
                                }
                            }
                        }
                    )
                }
            }
            .padding(DMSpace.l)
        }
        .onAppear {
            configManager.refreshAllPathStatuses()
        }
    }

    private var descriptionSection: some View {
        HStack(spacing: DMSpace.s) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.blue)

            Text(L(.scanPathDescription))
                .font(DMTypography.callout)
                .foregroundColor(.secondary)
        }
        .padding(DMSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .fill(Color.blue.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Language Path Config Card

/// 单个语言的路径配置卡片
struct LanguagePathConfigCard: View {
    let language: LanguageMetadata
    let isExpanded: Bool
    let onToggle: () -> Void

    @ObservedObject private var configManager = ScanPathConfigManager.shared
    @State private var newPath: String = ""

    private var builtInPaths: [ScanPathInfo] {
        BuiltInScanPaths.paths(for: language.id)
    }

    private var customPaths: [ScanPathInfo] {
        configManager.getCustomPaths(for: language.id).map { path in
            ScanPathInfo(
                path: path,
                source: .custom,
                displayName: "Custom",
                isBuiltIn: false
            )
        }
    }

    private var allPaths: [ScanPathInfo] {
        builtInPaths + customPaths
    }

    private var availablePathCount: Int {
        allPaths.filter { configManager.pathStatuses[$0.path]?.exists == true }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            // 展开内容
            if isExpanded {
                Divider()
                    .padding(.horizontal, DMSpace.m)

                VStack(alignment: .leading, spacing: DMSpace.m) {
                    // 内置路径
                    builtInPathsSection

                    // 自定义路径
                    customPathsSection

                    // 添加路径
                    addPathSection
                }
                .padding(DMSpace.m)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .fill(DMColor.controlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DMRadius.card)
                .stroke(DMColor.separator.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var headerView: some View {
        Button(action: onToggle) {
            HStack(spacing: DMSpace.m) {
                // 语言图标
                ZStack {
                    RoundedRectangle(cornerRadius: DMRadius.control)
                        .fill(language.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    LanguageIconView(imageName: language.iconName, size: 20)
                }

                // 语言名称
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(L(.scanPathSummary, allPaths.count, availablePathCount))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 展开指示器
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(DMSpace.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Built-in Paths Section

    private var builtInPathsSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.s) {
            HStack {
                Text(L(.scanPathBuiltIn))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                DMBadge(text: "\(builtInPaths.count)", accent: .gray, style: .subtle)
            }

            VStack(spacing: DMSpace.xs) {
                ForEach(builtInPaths) { pathInfo in
                    PathInfoRow(
                        pathInfo: pathInfo,
                        status: configManager.pathStatuses[pathInfo.path]
                    )
                }
            }
        }
    }

    // MARK: - Custom Paths Section

    private var customPathsSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.s) {
            HStack {
                Text(L(.scanPathCustom))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if !customPaths.isEmpty {
                    DMBadge(text: "\(customPaths.count)", accent: .blue, style: .subtle)
                }
            }

            if customPaths.isEmpty {
                Text(L(.scanPathNoCustom))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, DMSpace.xs)
            } else {
                VStack(spacing: DMSpace.xs) {
                    ForEach(customPaths) { pathInfo in
                        PathInfoRow(
                            pathInfo: pathInfo,
                            status: configManager.pathStatuses[pathInfo.path],
                            onDelete: {
                                withAnimation(DMAnimation.smooth) {
                                    configManager.removeCustomPath(
                                        for: language.id, path: pathInfo.path)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Add Path Section

    private var addPathSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.s) {
            Text(L(.scanPathAddCustom))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: DMSpace.s) {
                TextField(L(.scanPathPlaceholder), text: $newPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))

                Button(action: selectFolder) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .help(L(.sharedRevealInFinder))

                Button(L(.sharedAdd)) {
                    addPath()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPath.isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func addPath() {
        guard !newPath.isEmpty else { return }
        withAnimation(DMAnimation.smooth) {
            configManager.addCustomPath(for: language.id, path: newPath)
            newPath = ""
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = L(.scanPathSelectFolder)

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            withAnimation(DMAnimation.smooth) {
                configManager.addCustomPath(for: language.id, path: path)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
    struct ScanPathSettingsView_Previews: PreviewProvider {
        static var previews: some View {
            ScanPathSettingsView()
                .frame(width: 600, height: 500)
        }
    }
#endif
