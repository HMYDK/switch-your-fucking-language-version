# RuntimePilot

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0+-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

**RuntimePilot** 是一个原生 macOS 应用，为任意编程语言提供统一的运行时版本管理界面。  
通过单一 UI 发现已安装的运行时，快速切换版本，并将选定的版本配置到你的 Shell 环境中。

## ✨ 特性

### 🖥️ 原生 macOS 体验
- 使用 SwiftUI 构建，采用 NavigationSplitView + Grid 布局
- 可调整大小的窗口，左侧边栏选择语言，右侧详情面板展示版本卡片
- 现代化卡片式版本展示，配有官方语言图标
- 自定义 Design System（DMTheme），统一的间距、圆角、排版规范

### 🌍 多语言界面
- 支持 **英文** 和 **中文简体** 两种界面语言
- 可在设置中随时切换语言
- 所有界面文本均已本地化

### 📊 Dashboard 仪表板
- 一览所有语言环境的状态概览
- 显示已激活版本、安装来源、已安装数量
- 快速导航到各语言详情页
- 内置 Quick Start 引导，帮助新用户完成 Shell 配置

### 🎯 完全可配置的语言支持
- **自定义任意语言**：不仅限于内置语言，可添加任何编程语言或运行时
- **预设模板**：内置 9 种常见语言模板，一键添加：
  - Java JDK, Node.js, Python, Go（推荐）
  - Ruby, Rust, PHP, .NET, Flutter
- **可编辑配置**：每种语言的名称、图标、颜色、扫描路径均可自定义
- **环境变量**：可为每种语言配置对应的环境变量（如 `JAVA_HOME`、`GOROOT`）

### 📂 扫描路径配置
- **可视化管理**：在设置中查看和管理各语言的扫描路径
- **添加自定义路径**：支持手动输入或通过文件夹选择器添加路径
- **路径状态检测**：实时显示路径是否存在、是否可访问
- **支持通配符**：如 `/opt/homebrew/Cellar/node*`

### 🚀 首次使用引导
- **语言选择**：首次启动时选择要管理的编程语言
- **目录授权**：引导用户授权必要的目录访问权限
- **推荐配置**：默认推荐 Java、Node.js、Python、Go 四种常用语言

### 🔄 一致的交互体验
- 侧边栏选择语言，卡片列表展示所有已检测版本
- 当前激活版本固定在顶部并标记为 **Active**
- 每个版本卡片提供 **Use**、**Open in Finder**、**Uninstall** 等操作
- 支持复制路径、在 Finder 中显示等上下文操作

### 🐚 Shell 集成
- RuntimePilot **不直接修改**你的 Shell 配置文件
- 为每种语言生成小型 `*_env.sh` 脚本，存放于 `~/.config/devmanager/`
- 只需在 Shell 配置中 source 这些文件一次，应用切换版本时会自动更新它们

### ⚙️ 设置
- **通用设置**：切换界面语言（英文/中文）
- **扫描路径**：管理各语言的版本扫描路径

## 📋 系统要求

- macOS 13.0 或更高版本
- Swift 5.9+
- Homebrew（可选，安装/卸载功能需要）

## 🚀 如何运行

### 开发模式

```bash
# 构建
swift build

# 运行
swift run
```

### 生成应用包

```bash
# 构建 .app 和 .dmg
./build-app.sh
```

构建完成后：
- App 包：`.build/release/RuntimePilot.app`
- DMG 镜像：`RuntimePilot-0.0.1.dmg`

## ⚙️ Shell 配置（一次性设置）

将以下内容添加到你的 Shell 配置文件（如 `~/.zshrc` 或 `~/.bash_profile`）：

```bash
# RuntimePilot - Development Environment Manager
for env_file in ~/.config/devmanager/*_env.sh; do
    [ -f "$env_file" ] && source "$env_file"
done
```

或者单独配置各语言：

```bash
# Java
[ -f ~/.config/devmanager/java_env.sh ] && source ~/.config/devmanager/java_env.sh

# Node.js
[ -f ~/.config/devmanager/node_env.sh ] && source ~/.config/devmanager/node_env.sh

# Python
[ -f ~/.config/devmanager/python_env.sh ] && source ~/.config/devmanager/python_env.sh

# Go
[ -f ~/.config/devmanager/go_env.sh ] && source ~/.config/devmanager/go_env.sh
```

然后重新加载 Shell：

```bash
source ~/.zshrc
```

或者打开一个新的终端窗口。

之后，每当你在 RuntimePilot 中点击 **Use** 切换版本，对应的 `*_env.sh` 文件就会更新，新的 Shell 会话将使用选定的版本。

## 🏗️ 项目结构

```
RuntimePilot/
├── Sources/RuntimePilot/
│   ├── RuntimePilotApp.swift       # 应用入口
│   ├── ContentView.swift           # 主视图，NavigationSplitView 布局
│   ├── DashboardView.swift         # Dashboard 仪表板视图
│   ├── DashboardViewModel.swift    # Dashboard 视图模型
│   ├── GenericLanguageView.swift   # 通用语言详情视图
│   ├── SettingsView.swift          # 设置界面
│   ├── OnboardingView.swift        # 首次启动引导视图
│   │
│   ├── LanguageProtocols.swift     # 语言版本和管理器协议定义
│   ├── LanguageMetadata.swift      # 语言元数据（名称、图标、颜色等）
│   ├── LanguageRegistry.swift      # 语言注册表，管理所有语言
│   │
│   ├── CustomLanguage/             # 自定义语言模块
│   │   ├── CustomLanguageConfig.swift    # 自定义语言配置模型
│   │   ├── CustomLanguageManager.swift   # 自定义语言管理器
│   │   ├── CustomLanguageEditorView.swift# 语言编辑器视图
│   │   └── CustomVersionManager.swift    # 版本管理器实现
│   │
│   ├── ScanPathConfig.swift        # 扫描路径配置模型
│   ├── ScanPathConfigManager.swift # 扫描路径配置管理器
│   ├── ScanPathSettingsView.swift  # 扫描路径设置视图
│   ├── PathInfoRow.swift           # 路径信息行组件
│   │
│   ├── Localization/               # 本地化模块
│   │   ├── LocalizationManager.swift   # 本地化管理器
│   │   └── LocalizedStrings.swift      # 本地化字符串定义
│   │
│   ├── BrewService.swift           # Homebrew 服务
│   ├── BrewScanner.swift           # Homebrew 版本扫描
│   ├── VersionSorting.swift        # 版本号排序工具
│   │
│   ├── DirectoryAccessManager.swift# 目录访问权限管理
│   ├── MigrationManager.swift      # 数据迁移管理器
│   │
│   ├── DMTheme.swift               # Design System（间距、圆角、排版）
│   ├── SharedViews.swift           # 共享 UI 组件
│   └── Resources/                  # 语言图标资源
│
├── Package.swift                   # Swift Package 配置
├── Info.plist                      # 应用信息
├── build-app.sh                    # 构建脚本
└── README.md
```

## 🎨 架构设计

### 设计模式

- **Protocol-Oriented Design**：`LanguageVersion` 和 `LanguageManager` 协议定义统一契约
- **Type Erasure**：`AnyLanguageVersion` 和 `AnyLanguageManager` 实现类型擦除，支持泛型视图
- **Registry Pattern**：`LanguageRegistry` 作为语言注册中心，支持动态扩展
- **Singleton**：`CustomLanguageManager.shared`、`LocalizationManager.shared` 管理全局状态
- **MVVM**：视图与业务逻辑分离，使用 `@StateObject` 和 `@ObservedObject`
- **Template Pattern**：`LanguageTemplate` 提供预设语言配置模板

### 添加新语言

通过应用内的自定义语言功能添加新语言：

1. 打开应用，在侧边栏点击 **+** 按钮
2. 选择预设模板或手动配置：
   - 名称和标识符
   - 图标和颜色
   - 版本扫描路径
   - 环境变量名
3. 保存后即可开始使用

也可以通过设置 → 扫描路径来管理已添加语言的扫描路径。

## 📄 License

MIT License
