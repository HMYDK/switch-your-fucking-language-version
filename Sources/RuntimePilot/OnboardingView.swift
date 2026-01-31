import SwiftUI

/// 引导流程步骤
enum OnboardingStep {
    case selectLanguages
    case authorizeDirectories
}

/// 首次启动引导视图
/// 引导用户选择语言并授权访问版本管理目录
struct OnboardingView: View {
    @ObservedObject var accessManager: DirectoryAccessManager
    @Binding var isPresented: Bool
    var registry: LanguageRegistry

    @ObservedObject private var customLanguageManager = CustomLanguageManager.shared
    @State private var currentStep: OnboardingStep = .selectLanguages
    @State private var selectedTemplates: Set<LanguageTemplate> = LanguageTemplate.recommended
    @State private var authorizedPaths: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            switch currentStep {
            case .selectLanguages:
                languageSelectionView
            case .authorizeDirectories:
                directoryAccessView
            }
        }
        .frame(width: 650, height: 650)
        .onAppear {
            // 如果已有语言配置，跳过语言选择步骤
            if !customLanguageManager.customLanguages.isEmpty {
                currentStep = .authorizeDirectories
            }
            // 检查已有的授权目录
            for url in accessManager.authorizedDirectories {
                authorizedPaths.insert(url.path)
            }
        }
    }

    // MARK: - Language Selection View

    private var languageSelectionView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue.gradient)

                Text(L(.onboardingWelcome))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(L(.onboardingChooseLanguages))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Language Grid
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 140, maximum: 180))
                    ], spacing: 12
                ) {
                    ForEach(LanguageTemplate.allCases) { template in
                        LanguageTemplateCard(
                            template: template,
                            isSelected: selectedTemplates.contains(template),
                            onToggle: {
                                if selectedTemplates.contains(template) {
                                    selectedTemplates.remove(template)
                                } else {
                                    selectedTemplates.insert(template)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxHeight: 380)

            // Info note
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(L(.onboardingLanguageHint))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()

            // Footer buttons
            HStack(spacing: 16) {
                Button(L(.sharedSkip)) {
                    completeOnboarding()
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(selectedTemplates.count) \(L(.onboardingSelected))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(L(.sharedContinue)) {
                    addSelectedLanguages()
                    currentStep = .authorizeDirectories
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTemplates.isEmpty)
            }
            .padding(24)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Directory Access View

    private var directoryAccessView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue.gradient)

                Text(L(.onboardingDirectoryAccess))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(L(.onboardingDirectoryHint))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text(L(.onboardingDirectoryList))
                    .font(.headline)

                // Directory list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(recommendedPathsForSelectedLanguages, id: \.path) { item in
                            DirectoryAccessRow(
                                name: item.name,
                                path: item.path,
                                isAuthorized: authorizedPaths.contains(item.path),
                                onAuthorize: {
                                    authorizeDirectory(path: item.path)
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 300)

                // Info note
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text(L(.onboardingAccessNote))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Footer buttons
            HStack(spacing: 16) {
                if customLanguageManager.customLanguages.isEmpty {
                    Button(L(.sharedBack)) {
                        currentStep = .selectLanguages
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(L(.sharedSkip)) {
                        completeOnboarding()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(L(.sharedDone)) {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helper Properties

    /// 根据选择的语言获取推荐的目录列表
    private var recommendedPathsForSelectedLanguages: [(name: String, path: String)] {
        var paths: [(name: String, path: String)] = []
        var seenPaths = Set<String>()

        // 从已配置的语言中获取扫描路径
        for config in customLanguageManager.customLanguages {
            for scanPath in config.scanPaths {
                let expandedPath = (scanPath as NSString).expandingTildeInPath
                let basePath =
                    expandedPath.contains("*")
                    ? (expandedPath as NSString).deletingLastPathComponent
                    : expandedPath

                if !seenPaths.contains(basePath) {
                    seenPaths.insert(basePath)
                    let name = (basePath as NSString).lastPathComponent
                    paths.append((name: name, path: basePath))
                }
            }
        }

        // 添加通用推荐路径
        let generalPaths = DirectoryAccessManager.recommendedPaths
        for item in generalPaths {
            if !seenPaths.contains(item.path) {
                seenPaths.insert(item.path)
                paths.append(item)
            }
        }

        return paths
    }

    // MARK: - Actions

    private func addSelectedLanguages() {
        for template in selectedTemplates {
            // 检查是否已存在
            if !customLanguageManager.isIdentifierExists(template.id) {
                var config = template.config
                config.id = UUID()
                customLanguageManager.addLanguage(config)
            }
        }

        // 注册到 Registry
        customLanguageManager.registerToRegistry(registry)
    }

    private func authorizeDirectory(path: String) {
        Task { @MainActor in
            if let url = accessManager.requestDirectoryAccess(suggestedPath: path) {
                authorizedPaths.insert(url.path)
            }
        }
    }

    private func completeOnboarding() {
        accessManager.completeOnboarding()
        isPresented = false
    }
}

/// 语言模板选择卡片
struct LanguageTemplateCard: View {
    let template: LanguageTemplate
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            Color(hex: template.config.colorHex)?.opacity(0.15)
                                ?? Color.blue.opacity(0.15)
                        )
                        .frame(width: 48, height: 48)

                    LanguageIconView(imageName: template.config.iconSymbol, size: 28)
                }

                // Name
                Text(template.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.accentColor : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// 目录授权行视图
struct DirectoryAccessRow: View {
    let name: String
    let path: String
    let isAuthorized: Bool
    let onAuthorize: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isAuthorized ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: isAuthorized ? "checkmark.folder.fill" : "folder")
                    .font(.system(size: 18))
                    .foregroundColor(isAuthorized ? .green : .secondary)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.callout)
                    .fontWeight(.medium)

                Text(path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Action
            if isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            } else {
                Button(L(.onboardingGrantAccess)) {
                    onAuthorize()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// 设置中的目录管理视图
struct DirectoryAccessSettingsView: View {
    @ObservedObject var accessManager: DirectoryAccessManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L(.settingsAuthorizedDirs))
                .font(.headline)

            if accessManager.authorizedDirectories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text(L(.settingsNoDirs))
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Button(L(.settingsAddDir)) {
                        _ = accessManager.requestDirectoryAccess()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                ForEach(accessManager.authorizedDirectories, id: \.path) { url in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)

                        Text(url.path)
                            .font(.callout)
                            .lineLimit(1)

                        Spacer()

                        Button {
                            accessManager.removeAuthorization(for: url)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }

                Button(L(.settingsAddDir)) {
                    _ = accessManager.requestDirectoryAccess()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
