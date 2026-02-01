import AppKit
import SwiftUI

struct GenericLanguageView: View {
    let metadata: LanguageMetadata
    @ObservedObject var manager: AnyLanguageManager
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var showSwitchAlert = false
    @State private var lastSwitchedVersion: AnyLanguageVersion?

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
        .alert(L(.versionSwitchTitle), isPresented: $showSwitchAlert) {
            Button(L(.versionSwitchOpenTerminal)) {
                openTerminal()
            }
            Button(L(.versionSwitchDismiss), role: .cancel) { }
        } message: {
            if let version = lastSwitchedVersion {
                Text(L(.versionSwitchMessage, metadata.displayName, version.version))
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
                        color: metadata.color,
                        onUse: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                manager.setActive(version)
                                lastSwitchedVersion = version
                                showSwitchAlert = true
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
                LanguageIconView(imageName: metadata.iconName, size: 32)
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
                            Text("Select a version to generate environment configuration.")
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
