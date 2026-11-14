import Combine
import Foundation
import SwiftUI

// MARK: - Language Version Protocol

/// 定义版本对象的最小契约
protocol LanguageVersion: Identifiable {
    var id: UUID { get }
    var version: String { get }
    var source: String { get }
    var path: String { get }
}

// MARK: - Language Manager Protocol

/// 定义所有语言管理器必须遵循的契约
/// App Store 版本仅提供版本检测和环境切换功能
protocol LanguageManager: AnyObject, ObservableObject {
    associatedtype Version: LanguageVersion

    var installedVersions: [Version] { get }
    var activeVersion: Version? { get }

    func refresh()

    /// 切换版本并写入环境脚本。返回 false 表示脚本生成/写入失败，调用方必须提示用户。
    @discardableResult
    func setActive(_ version: Version) -> Bool
}

// MARK: - Type Erased Language Version

/// 类型擦除的版本包装器
struct AnyLanguageVersion: LanguageVersion {
    let id: UUID
    let version: String
    let source: String
    let path: String

    init<V: LanguageVersion>(_ version: V) {
        self.id = version.id
        self.version = version.version
        self.source = version.source
        self.path = version.path
    }
}

// MARK: - Type Erased Language Manager

/// 类型擦除的管理器包装器
class AnyLanguageManager: ObservableObject {
    @Published private(set) var installedVersions: [AnyLanguageVersion] = []
    @Published private(set) var activeVersion: AnyLanguageVersion?

    private let _refresh: () -> Void
    private let _setActive: (AnyLanguageVersion) -> Bool

    private var cancellables = Set<AnyCancellable>()

    init<M: LanguageManager>(_ manager: M) {
        // 初始化版本列表
        self.installedVersions = manager.installedVersions.map { AnyLanguageVersion($0) }
        self.activeVersion = manager.activeVersion.map { AnyLanguageVersion($0) }

        // 保存闭包引用
        _refresh = { [weak manager] in
            manager?.refresh()
        }

        _setActive = { [weak manager] anyVersion in
            guard let manager = manager else { return false }
            // 优先按 UUID 查找，刷新后 UUID 会变化，因此再按路径兜底
            guard let originalVersion = manager.installedVersions.first(where: {
                $0.id == anyVersion.id
            }) ?? manager.installedVersions.first(where: {
                $0.path == anyVersion.path
            }) else {
                return false
            }
            return manager.setActive(originalVersion)
        }

        // 只在底层 Manager 真正发生变化时同步一次，不再使用 100ms 轮询。
        // objectWillChange 在属性变更前发出，因此将读取推迟到下一个主线程周期。
        manager.objectWillChange
            .sink { [weak self, weak manager] _ in
                DispatchQueue.main.async {
                    guard let self = self, let manager = manager else { return }
                    self.installedVersions = manager.installedVersions.map { AnyLanguageVersion($0) }
                    self.activeVersion = manager.activeVersion.map { AnyLanguageVersion($0) }
                }
            }
            .store(in: &cancellables)
    }

    func refresh() {
        _refresh()
    }

    @discardableResult
    func setActive(_ version: AnyLanguageVersion) -> Bool {
        _setActive(version)
    }
}
