import AppKit
import SwiftUI

// MARK: - Scan Path Settings View

/// 扫描路径设置视图 - 管理各语言的扫描路径配置
struct ScanPathSettingsView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var configManager = ScanPathConfigManager.shared
    @ObservedObject private var customLanguageManager = CustomLanguageManager.shared

    @State private var expandedLanguages: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DMSpace.l) {
                // 说明文本
                descriptionSection

                // 语言配置列表
                if customLanguageManager.customLanguages.isEmpty {
                    emptyStateView
                } else {
                    ForEach(customLanguageManager.customLanguages) { config in
                        LanguagePathConfigCard(
                            config: config,
                            isExpanded: expandedLanguages.contains(config.identifier),
                            onToggle: {
                                withAnimation(DMAnimation.smooth) {
                                    if expandedLanguages.contains(config.identifier) {
                                        expandedLanguages.remove(config.identifier)
                                    } else {
                                        expandedLanguages.insert(config.identifier)
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .padding(DMSpace.l)
        }
        .onAppear {
            // 刷新所有语言的路径状态
            for config in customLanguageManager.customLanguages {
                configManager.refreshPathStatuses(for: config.scanPaths)
            }
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

    private var emptyStateView: some View {
        VStack(spacing: DMSpace.m) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(L(.scanPathNoLanguages))
                .font(DMTypography.body)
                .foregroundColor(.secondary)

            Text(L(.scanPathAddLanguageHint))
                .font(DMTypography.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DMSpace.xxl)
    }
}

// MARK: - Language Path Config Card

/// 单个语言的路径配置卡片
struct LanguagePathConfigCard: View {
    let config: CustomLanguageConfig
    let isExpanded: Bool
    let onToggle: () -> Void

    @ObservedObject private var configManager = ScanPathConfigManager.shared
    @ObservedObject private var customLanguageManager = CustomLanguageManager.shared
    @State private var newPath: String = ""

    private var scanPaths: [ScanPathInfo] {
        config.scanPaths.map { path in
            ScanPathInfo(path: path)
        }
    }

    private var availablePathCount: Int {
        scanPaths.filter { configManager.pathStatuses[$0.path]?.exists == true }.count
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
                    // 配置路径
                    pathsSection

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
                        .fill(config.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    if config.iconType == .customImage {
                        LanguageIconView(imageName: config.iconSymbol, size: 20)
                    } else {
                        Image(systemName: config.iconSymbol)
                            .font(.system(size: 16))
                            .foregroundColor(config.color)
                    }
                }

                // 语言名称
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(L(.scanPathSummary, scanPaths.count, availablePathCount))
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

    // MARK: - Paths Section

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.s) {
            HStack {
                Text(L(.scanPathConfigured))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                DMBadge(text: "\(scanPaths.count)", accent: .gray, style: .subtle)
            }

            if scanPaths.isEmpty {
                Text(L(.scanPathNoConfigured))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, DMSpace.xs)
            } else {
                VStack(spacing: DMSpace.xs) {
                    ForEach(scanPaths) { pathInfo in
                        PathInfoRow(
                            pathInfo: pathInfo,
                            status: configManager.pathStatuses[pathInfo.path],
                            onDelete: {
                                withAnimation(DMAnimation.smooth) {
                                    removePathFromConfig(pathInfo.path)
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
            addPathToConfig(newPath)
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
                addPathToConfig(path)
            }
        }
    }

    private func addPathToConfig(_ path: String) {
        var updatedConfig = config
        if !updatedConfig.scanPaths.contains(path) {
            updatedConfig.scanPaths.append(path)
            customLanguageManager.updateLanguage(updatedConfig)
            configManager.checkPathStatusAsync(path)
        }
    }

    private func removePathFromConfig(_ path: String) {
        var updatedConfig = config
        updatedConfig.scanPaths.removeAll { $0 == path }
        customLanguageManager.updateLanguage(updatedConfig)
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
