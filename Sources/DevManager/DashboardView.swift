import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selection: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar.horizontal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Text("Overview of your development environments")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 24)
                
                // Welcome message for first-time users
                if !viewModel.hasAnyConfigured {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome to DevManager")
                                .font(.callout)
                                .fontWeight(.semibold)
                            Text("Select a language card below to start managing your development environment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                }
                
                // Language Cards Grid
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 320), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.languageStatuses) { status in
                        LanguageStatusCard(
                            status: status,
                            onTap: {
                                withAnimation {
                                    selection = status.id
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Language Status Card

struct LanguageStatusCard: View {
    let status: LanguageStatus
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Top section with icon and language name
                HStack(spacing: 16) {
                    // Language icon
                    ZStack {
                        Circle()
                            .fill(
                                status.isConfigured
                                    ? status.color.opacity(0.15)
                                    : Color.gray.opacity(0.1)
                            )
                            .frame(width: 64, height: 64)
                        
                        LanguageIconView(
                            imageName: status.iconName,
                            size: 48
                        )
                        .opacity(status.isConfigured ? 1.0 : 0.5)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Language name
                        Text(status.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Status indicator
                        if status.isConfigured {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(status.color)
                                Text("Configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("Not configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Arrow indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                
                Divider()
                
                // Version information
                if status.isConfigured, let version = status.activeVersion {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current Version")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 8) {
                            Text(version)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if let source = status.activeSource {
                                SourceTagView(source: source)
                            }
                        }
                        
                        // Installed count
                        if status.installedCount > 0 {
                            Text("\(status.installedCount) version\(status.installedCount == 1 ? "" : "s") installed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // Not configured state
                    VStack(alignment: .leading, spacing: 8) {
                        if status.installedCount > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                
                                Text("No version selected")
                                    .font(.callout)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("\(status.installedCount) version\(status.installedCount == 1 ? "" : "s") available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                
                                Text("No versions installed")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Click to install and configure")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        status.isConfigured
                            ? status.color.opacity(0.5)
                            : Color.gray.opacity(0.2),
                        lineWidth: status.isConfigured ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.08 : 0),
                radius: isHovered ? 8 : 0,
                x: 0,
                y: isHovered ? 4 : 0
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.25)) {
                isHovered = hovering
            }
        }
    }
}
