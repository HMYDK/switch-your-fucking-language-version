import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label(L(.settingsGeneral), systemImage: "gear")
                }
        }
        .frame(width: 450, height: 250)
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        Form {
            Section {
                Picker(L(.settingsLanguage), selection: $localization.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.nativeDisplayName)
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)

                Text(L(.settingsLanguageDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
    struct SettingsView_Previews: PreviewProvider {
        static var previews: some View {
            SettingsView()
        }
    }
#endif
