import Foundation

/// 自定义语言配置的纯校验规则。
/// 错误文案由 UI 层负责本地化，core 只返回稳定的 issue 枚举。
public enum LanguageConfigValidation {

    public enum Issue: Equatable {
        case nameRequired
        case identifierRequired
        case identifierInvalid
        case scanPathRequired
        case environmentVariableInvalid
        case environmentVariableReserved
    }

    private static let identifierFirstCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    private static let identifierAllowedCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    private static let environmentVariableFirstCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
    private static let environmentVariableAllowedCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")

    /// 设置这些变量会破坏当前 shell 或用户环境，不允许作为版本环境变量
    public static let reservedEnvironmentVariables: Set<String> = [
        "PATH", "HOME", "SHELL", "USER", "LOGNAME", "TMPDIR", "PWD", "OLDPWD",
    ]

    public static func isValidIdentifier(_ identifier: String) -> Bool {
        guard let first = identifier.unicodeScalars.first,
            identifierFirstCharacters.contains(first)
        else {
            return false
        }
        return identifier.unicodeScalars.allSatisfy {
            identifierAllowedCharacters.contains($0)
        }
    }

    public static func isValidEnvironmentVariableName(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first,
            environmentVariableFirstCharacters.contains(first)
        else {
            return false
        }
        return name.unicodeScalars.allSatisfy {
            environmentVariableAllowedCharacters.contains($0)
        }
    }

    public static func isReservedEnvironmentVariable(_ name: String) -> Bool {
        reservedEnvironmentVariables.contains(name.uppercased())
    }

    public static func validate(
        name: String,
        identifier: String,
        scanPaths: [String],
        envVarName: String?
    ) -> [Issue] {
        var issues: [Issue] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.nameRequired)
        }

        if identifier.isEmpty {
            issues.append(.identifierRequired)
        } else if !isValidIdentifier(identifier) {
            issues.append(.identifierInvalid)
        }

        if scanPaths.isEmpty {
            issues.append(.scanPathRequired)
        }

        if let rawName = envVarName {
            let variableName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !variableName.isEmpty {
                if !isValidEnvironmentVariableName(variableName) {
                    issues.append(.environmentVariableInvalid)
                } else if isReservedEnvironmentVariable(variableName) {
                    issues.append(.environmentVariableReserved)
                }
            }
        }

        return issues
    }
}
