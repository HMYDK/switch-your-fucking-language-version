import SwiftUI

/// 首次启动引导视图
/// 引导用户授权访问版本管理目录
struct OnboardingView: View {
    @ObservedObject var accessManager: DirectoryAccessManager
    @Binding var isPresented: Bool

    @State private var currentStep = 0
    @State private var authorizedPaths: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue.gradient)

                Text("Welcome to RuntimePilot")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Grant access to scan your development environment versions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text("RuntimePilot needs access to scan version directories:")
                    .font(.headline)

                // Directory list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(DirectoryAccessManager.recommendedPaths, id: \.path) { item in
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
                .frame(maxHeight: 280)

                // Info note
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text(
                        "You can manage directory access later in Settings. Only grant access to directories where you have installed development tools."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 40)

            Spacer()

            // Footer buttons
            HStack(spacing: 16) {
                Button("Skip for Now") {
                    completeOnboarding()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Continue") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(authorizedPaths.isEmpty)
            }
            .padding(24)
            .background(.ultraThinMaterial)
        }
        .frame(width: 600, height: 600)
        .onAppear {
            // 检查已有的授权目录
            for url in accessManager.authorizedDirectories {
                authorizedPaths.insert(url.path)
            }
        }
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
                Button("Grant Access") {
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
            Text("Authorized Directories")
                .font(.headline)

            if accessManager.authorizedDirectories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("No directories authorized")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Button("Add Directory") {
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

                Button("Add Directory") {
                    _ = accessManager.requestDirectoryAccess()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
