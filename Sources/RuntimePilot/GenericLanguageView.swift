import AppKit
import SwiftUI

struct GenericLanguageView: View {
    let metadata: LanguageMetadata
    @ObservedObject var manager: AnyLanguageManager
    @ObservedObject private var localization = LocalizationManager.shared

    private enum SwitchFeedback: Identifiable {
        case success(AnyLanguageVersion)
        case failure(AnyLanguageVersion)

        var id: String {
            switch self {
            case .success(let version):
                return "success-\(version.id)"
            case .failure(let version):
                return "failure-\(version.id)"
            }
        }
    }

    @State private var switchFeedback: SwitchFeedback?

    private var displayedVersions: [AnyLanguageVersion] {
        var sorted = manager.installedVersions.sorted { lhs, rhs in
            compareVersionDescending(lhs.version, rhs.version)
        }

        if let active = manager.activeVersion {
            sorted.removeAll(where: { $0.id == active.id })
            return [active] + sorted
        }

        return sorted
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            // Content area
            if manager.installedVersions.isEmpty {
                ModernEmptyState(
                    iconImage: metadata.iconName,
                    iconType: metadata.iconType,
                    title: L(.languageNoVersionsFound, metadata.displayName),
                    message: L(.languageInstallHint),
                    color: metadata.color,
                    onRefresh: { manager.refresh() }
                )
            } else {
                // 操作栏
                VersionActionBar(
                    installedCount: manager.installedVersions.count,
                    color: metadata.color
                )

                versionsTable
            }

            // Config hint at bottom
            ConfigHintView(filename: metadata.configFileName)
        }
        .navigationTitle(metadata.displayName)
        .toolbar {
            ToolbarItem {
                Button {
                    manager.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(L(.languageRefresh))
                .accessibilityLabel(L(.languageRefresh))
            }
        }
        .alert(item: $switchFeedback) { feedback in
            switch feedback {
            case .success(let version):
                return Alert(
                    title: Text(L(.versionSwitchTitle)),
                    message: Text(
                        L(.versionSwitchMessage, metadata.displayName, version.version)),
                    primaryButton: .default(Text(L(.versionSwitchOpenTerminal))) {
                        openTerminal()
                    },
                    secondaryButton: .cancel(Text(L(.versionSwitchDismiss)))
                )
            case .failure(let version):
                return Alert(
                    title: Text(L(.versionSwitchFailedTitle)),
                    message: Text(
                        L(.versionSwitchFailedMessage, metadata.displayName, version.version)),
                    dismissButton: .default(Text(L(.sharedOk)))
                )
            }
        }
    }

    private var versionsTable: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 280, maximum: 380), spacing: DMSpace.l)],
                spacing: DMSpace.l
            ) {
                ForEach(displayedVersions) { version in
                    ModernVersionCard(
                        version: version.version,
                        source: version.source,
                        path: version.path,
                        isActive: manager.activeVersion?.id == version.id,
                        iconImage: metadata.iconName,
                        iconType: metadata.iconType,
                        color: metadata.color,
                        onUse: {
                            let succeeded = manager.setActive(version)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                switchFeedback = succeeded ? .success(version) : .failure(version)
                            }
                        },
                        onOpenFinder: {
                            NSWorkspace.shared.activateFileViewerSelecting(
                                [URL(fileURLWithPath: version.path)]
                            )
                        }
                    )
                }
            }
            .padding(DMSpace.l)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DMSpace.l) {
            HStack(spacing: DMSpace.m) {
                LanguageIconView(
                    imageName: metadata.iconName, iconType: metadata.iconType, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(metadata.displayName)
                        .font(DMTypography.title2)
                    Text(L(.languageManageVersions))
                        .font(DMTypography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            DMCard(accent: metadata.color, isEmphasized: manager.activeVersion != nil) {
                if let active = manager.activeVersion {
                    VStack(alignment: .leading, spacing: DMSpace.s) {
                        HStack(spacing: DMSpace.xs) {
                            DMBadge(text: L(.languageActive), accent: metadata.color)
                            Text(active.version)
                                .font(DMTypography.section)
                            Spacer()
                        }

                        DMKeyValueRow(
                            key: L(.languageSource),
                            value: active.source,
                            onCopy: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(active.source, forType: .string)
                            }
                        )

                        DMKeyValueRow(
                            key: L(.languagePath),
                            value: active.path,
                            isMonospaced: true,
                            onCopy: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(active.path, forType: .string)
                            }
                        )
                    }
                } else {
                    HStack(spacing: DMSpace.s) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L(.languageNoActiveVersion))
                                .font(DMTypography.section)
                            Text(L(.languageSelectVersionHint))
                                .font(DMTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, DMSpace.xxl)
        .padding(.vertical, DMSpace.xl)
    }

    private func openTerminal() {
        // Use Process to launch Terminal via 'open' command
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-b", "com.apple.Terminal"]
        try? task.run()
    }
}
