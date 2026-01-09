import AppKit
import SwiftUI

struct GenericLanguageView: View {
    let metadata: LanguageMetadata
    @ObservedObject var manager: AnyLanguageManager
    
    @State private var versionToUninstall: AnyLanguageVersion?
    @State private var showUninstallConfirmation = false
    @State private var isUninstalling = false
    @State private var uninstallingVersionId: UUID?
    @State private var showVersionManager = false

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
            // Modern header
            ModernHeaderView(
                title: metadata.displayName,
                iconImage: metadata.iconName,
                color: metadata.color,
                activeVersion: manager.activeVersion?.version,
                activeSource: manager.activeVersion?.source,
                activePath: manager.activeVersion?.path
            )

            // Content area
            if manager.installedVersions.isEmpty {
                ModernEmptyState(
                    iconImage: metadata.iconName,
                    title: "No \(metadata.displayName) Versions Found",
                    message: "Install via Homebrew or version manager, then refresh.",
                    color: metadata.color,
                    onRefresh: { manager.refresh() },
                    onInstallNew: { showVersionManager = true }
                )
            } else {
                // 操作栏
                VersionActionBar(
                    installedCount: manager.installedVersions.count,
                    color: metadata.color,
                    onInstallNew: { showVersionManager = true }
                )
                
                cardsGrid
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
                .help("Refresh")
            }
        }
        .sheet(isPresented: $showVersionManager) {
            VersionManagerSheet(
                viewModel: VersionInstallViewModel(language: getLanguageEnum(metadata.id)),
                onDismiss: { showVersionManager = false },
                onComplete: { manager.refresh() }
            )
        }
    }

    private var cardsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 280, maximum: 420), spacing: 20)
                ],
                spacing: 16
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
                            withAnimation(.easeInOut(duration: 0.4)) {
                                manager.setActive(version)
                            }
                        },
                        onOpenFinder: {
                            NSWorkspace.shared.activateFileViewerSelecting(
                                [URL(fileURLWithPath: version.path)]
                            )
                        },
                        canUninstall: manager.canUninstall(version),
                        onUninstall: {
                            versionToUninstall = version
                            showUninstallConfirmation = true
                        },
                        isUninstalling: uninstallingVersionId == version.id
                    )
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $showUninstallConfirmation) {
            Alert(
                title: Text("Confirm Uninstall"),
                message: Text("Are you sure you want to uninstall \(versionToUninstall?.version ?? "this version")? This action cannot be undone."),
                primaryButton: .destructive(Text("Uninstall")) {
                    if let version = versionToUninstall {
                        performUninstall(version)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func performUninstall(_ version: AnyLanguageVersion) {
        isUninstalling = true
        uninstallingVersionId = version.id
        
        Task {
            let success = await manager.uninstall(version) { output in
                print("Uninstall output: \(output)")
            }
            
            await MainActor.run {
                isUninstalling = false
                uninstallingVersionId = nil
                
                if success {
                    manager.refresh()
                }
            }
        }
    }
    
    // Helper function to convert string ID to LanguageType enum
    private func getLanguageEnum(_ id: String) -> VersionInstallViewModel.LanguageType {
        switch id {
        case "java": return .java
        case "node": return .node
        case "python": return .python
        case "go": return .go
        default: return .java
        }
    }
}
