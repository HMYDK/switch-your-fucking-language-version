import SwiftUI

// MARK: - Custom Language Editor View

struct CustomLanguageEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var customLanguageManager = CustomLanguageManager.shared

    @State private var config: CustomLanguageConfig
    @State private var showingIconPicker = false
    @State private var showingDeleteConfirm = false
    @State private var validationError: String?
    @State private var newPath: String = ""

    private let isEditing: Bool
    private let onSave: ((CustomLanguageConfig) -> Void)?

    // 创建新语言
    init(onSave: ((CustomLanguageConfig) -> Void)? = nil) {
        self._config = State(initialValue: CustomLanguageConfig())
        self.isEditing = false
        self.onSave = onSave
    }

    // 编辑现有语言
    init(config: CustomLanguageConfig, onSave: ((CustomLanguageConfig) -> Void)? = nil) {
        self._config = State(initialValue: config)
        self.isEditing = true
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            Divider()

            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: DMSpace.l) {
                    // 基本信息
                    basicInfoSection

                    Divider()

                    // 外观设置
                    appearanceSection

                    Divider()

                    // 扫描路径
                    scanPathsSection

                    Divider()

                    // 高级选项
                    advancedSection

                    // 预览
                    previewSection
                }
                .padding(DMSpace.l)
            }

            Divider()

            // 底部按钮
            footerView
        }
        .frame(width: 500, height: 650)
        .alert(L(.customLanguageDeleteConfirm), isPresented: $showingDeleteConfirm) {
            Button(L(.sharedCancel), role: .cancel) {}
            Button(L(.sharedDelete), role: .destructive) {
                deleteAndDismiss()
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            SFSymbolPickerView(selectedSymbol: $config.iconSymbol)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(isEditing ? L(.customLanguageEdit) : L(.customLanguageAdd))
                .font(.headline)
            Spacer()
        }
        .padding(DMSpace.m)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.m) {
            Text(L(.customLanguageName))
                .font(.subheadline)
                .fontWeight(.medium)

            TextField(L(.customLanguageNamePlaceholder), text: $config.name)
                .textFieldStyle(.roundedBorder)
                .onChange(of: config.name) { newValue in
                    // 自动生成 identifier
                    if !isEditing && config.identifier.isEmpty
                        || config.identifier
                            == generateIdentifier(from: String(config.name.dropLast()))
                    {
                        config.identifier = generateIdentifier(from: newValue)
                    }
                }

            Text(L(.customLanguageIdentifier))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, DMSpace.s)

            TextField(L(.customLanguageIdentifierPlaceholder), text: $config.identifier)
                .textFieldStyle(.roundedBorder)
                .disabled(isEditing)
                .foregroundColor(isEditing ? .secondary : .primary)

            if isEditing {
                Text("Identifier cannot be changed after creation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.m) {
            Text(L(.customLanguageIcon))
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                // 图标预览
                ZStack {
                    RoundedRectangle(cornerRadius: DMRadius.control)
                        .fill(config.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    if config.iconType == .customImage {
                        LanguageIconView(imageName: config.iconSymbol, size: 24)
                    } else {
                        Image(systemName: config.iconSymbol)
                            .font(.system(size: 20))
                            .foregroundColor(config.color)
                    }
                }

                Button(action: { showingIconPicker = true }) {
                    Text("Choose Icon...")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(config.iconType == .customImage)
            }

            Text(L(.customLanguageColor))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, DMSpace.s)

            HStack {
                ColorPicker(
                    "",
                    selection: Binding(
                        get: { config.color },
                        set: { newColor in
                            if let hex = newColor.toHex() {
                                config.colorHex = hex
                            }
                        }
                    )
                )
                .labelsHidden()

                TextField("#RRGGBB", text: $config.colorHex)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
        }
    }

    // MARK: - Scan Paths Section

    private var scanPathsSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.m) {
            HStack {
                Text(L(.customLanguageScanPaths))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button(action: addPath) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }

            // 路径列表
            if config.scanPaths.isEmpty {
                Text("No paths configured")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.vertical, DMSpace.s)
            } else {
                ForEach(config.scanPaths.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)

                        Text(config.scanPaths[index])
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button(action: { removePath(at: index) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(DMSpace.s)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(DMRadius.control)
                }
            }

            // 添加新路径
            HStack {
                TextField("~/path/to/versions", text: $newPath)
                    .textFieldStyle(.roundedBorder)

                Button(action: selectFolder) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.bordered)

                Button(L(.sharedAdd), action: addNewPath)
                    .buttonStyle(.bordered)
                    .disabled(newPath.isEmpty)
            }

            // 预设模板
            DisclosureGroup("Quick Add Templates") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: DMSpace.s) {
                    ForEach(LanguageTemplate.allCases) { template in
                        Button(action: { applyTemplate(template) }) {
                            Text(template.displayName)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            customLanguageManager.isIdentifierExists(template.config.identifier))
                    }
                }
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        DisclosureGroup("Advanced Options") {
            VStack(alignment: .leading, spacing: DMSpace.m) {
                Text(L(.customLanguageEnvVar))
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField(
                    L(.customLanguageEnvVarPlaceholder),
                    text: Binding(
                        get: { config.envVarName ?? "" },
                        set: { config.envVarName = $0.isEmpty ? nil : $0 }
                    )
                )
                .textFieldStyle(.roundedBorder)

                Text(
                    "The environment variable that will be set to point to the active version path."
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.top, DMSpace.s)
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: DMSpace.m) {
            Text(L(.customLanguagePreview))
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: DMSpace.m) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: DMRadius.control)
                        .fill(config.color.opacity(0.15))
                        .frame(width: 32, height: 32)

                    if config.iconType == .customImage {
                        LanguageIconView(imageName: config.iconSymbol, size: 16)
                    } else {
                        Image(systemName: config.iconSymbol)
                            .font(.system(size: 14))
                            .foregroundColor(config.color)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name.isEmpty ? "Language Name" : config.name)
                        .font(.system(size: 13, weight: .medium))

                    Text("\(config.scanPaths.count) scan path(s)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(DMSpace.m)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(DMRadius.card)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            if isEditing {
                Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                    Text(L(.sharedDelete))
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(L(.sharedCancel)) {
                dismiss()
            }
            .keyboardShortcut(.escape)

            Button(L(.sharedSave)) {
                save()
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .disabled(!config.isValid)
        }
        .padding(DMSpace.m)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Actions

    private func generateIdentifier(from name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".", with: "")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }

    private func addPath() {
        selectFolder()
    }

    private func addNewPath() {
        guard !newPath.isEmpty else { return }
        config.scanPaths.append(newPath)
        newPath = ""
    }

    private func removePath(at index: Int) {
        config.scanPaths.remove(at: index)
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a directory to scan for versions"

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            if !config.scanPaths.contains(path) {
                config.scanPaths.append(path)
            }
        }
    }

    private func applyTemplate(_ template: LanguageTemplate) {
        let templateConfig = template.config
        config.name = templateConfig.name
        config.identifier = templateConfig.identifier
        config.iconSymbol = templateConfig.iconSymbol
        config.colorHex = templateConfig.colorHex
        config.scanPaths = templateConfig.scanPaths
        config.envVarName = templateConfig.envVarName
        config.iconType = templateConfig.iconType
    }

    private func save() {
        // 验证
        guard config.isValid else {
            validationError = config.validationErrors.first
            return
        }

        // 检查 identifier 是否已存在
        if !isEditing && customLanguageManager.isIdentifierExists(config.identifier) {
            validationError = "Identifier already exists"
            return
        }

        // 保存
        if isEditing {
            customLanguageManager.updateLanguage(config)
        } else {
            customLanguageManager.addLanguage(config)
        }

        onSave?(config)
        dismiss()
    }

    private func deleteAndDismiss() {
        customLanguageManager.deleteLanguage(id: config.id)
        dismiss()
    }
}

// MARK: - SF Symbol Picker View

struct SFSymbolPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSymbol: String
    @State private var searchText = ""

    // 常用的 SF Symbols
    private let symbols = [
        "cube.fill", "diamond.fill", "hexagon.fill", "pentagon.fill",
        "triangle.fill", "square.fill", "circle.fill", "star.fill",
        "bolt.fill", "flame.fill", "leaf.fill", "drop.fill",
        "gear", "gearshape.fill", "gearshape.2.fill", "wrench.fill",
        "hammer.fill", "screwdriver.fill", "cpu.fill", "memorychip.fill",
        "terminal.fill", "chevron.left.forwardslash.chevron.right",
        "curlybraces", "ellipsis.curlybraces", "function",
        "number", "textformat", "doc.fill", "doc.text.fill",
        "folder.fill", "tray.fill", "archivebox.fill",
        "shippingbox.fill", "cube.box.fill", "square.stack.3d.up.fill",
        "puzzlepiece.fill", "building.columns.fill",
        "bird.fill", "hare.fill", "tortoise.fill", "ant.fill",
        "ladybug.fill", "fish.fill", "pawprint.fill",
        "globe", "network", "antenna.radiowaves.left.and.right",
        "wifi", "link", "paperclip", "externaldrive.fill",
        "internaldrive.fill", "opticaldiscdrive.fill",
        "server.rack", "desktopcomputer", "display",
        "laptopcomputer", "keyboard.fill", "computermouse.fill",
    ]

    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return symbols
        }
        return symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search symbols...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(DMSpace.m)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // 图标网格
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: DMSpace.m) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button(action: {
                            selectedSymbol = symbol
                            dismiss()
                        }) {
                            Image(systemName: symbol)
                                .font(.system(size: 24))
                                .frame(width: 50, height: 50)
                                .background(
                                    selectedSymbol == symbol
                                        ? Color.accentColor.opacity(0.2)
                                        : Color.clear
                                )
                                .cornerRadius(DMRadius.control)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(DMSpace.m)
            }

            Divider()

            // 底部按钮
            HStack {
                Spacer()
                Button(L(.sharedCancel)) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding(DMSpace.m)
        }
        .frame(width: 400, height: 450)
    }
}

// MARK: - Preview

#if DEBUG
    struct CustomLanguageEditorView_Previews: PreviewProvider {
        static var previews: some View {
            CustomLanguageEditorView()
        }
    }
#endif
