import Foundation

let brewPath = "/opt/homebrew/bin/brew"

func searchFormulae(pattern: String) -> [String] {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: brewPath)
    task.arguments = ["search", "/\(pattern)/"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }
        
        print("Raw Output:\n\(output)")
        
        let lines = output.components(separatedBy: .newlines)
        var results: [String] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty || trimmedLine.contains("==>") { continue }

            let parts = line.components(separatedBy: .whitespaces)
            for part in parts {
                let cleanPart = part.trimmingCharacters(in: .whitespaces)
                if !cleanPart.isEmpty && cleanPart != "✔" {
                    results.append(cleanPart)
                }
            }
        }
        return results
    } catch {
        print("Error: \(error)")
        return []
    }
}

struct FormulaInfo {
    let version: String
    let isInstalled: Bool
}

func getBatchFormulaeInfo(_ formulae: [String]) -> [String: FormulaInfo] {
    guard !formulae.isEmpty else { return [:] }

    let task = Process()
    task.executableURL = URL(fileURLWithPath: brewPath)
    task.arguments = ["info", "--json=v2"] + formulae

    let pipe = Pipe()
    task.standardOutput = pipe
    // task.standardError = Pipe() // Let stderr print to console to see errors

    do {
        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if data.isEmpty {
            print("Error: brew info returned empty data")
            return [:]
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Error: Failed to parse JSON")
            return [:]
        }
        
        guard let formulaeList = json["formulae"] as? [[String: Any]] else {
            print("Error: JSON does not contain 'formulae' list")
            return [:]
        }

        var result: [String: FormulaInfo] = [:]

        for formulaData in formulaeList {
            if let name = formulaData["name"] as? String {
                let versions = formulaData["versions"] as? [String: Any]
                let stable = versions?["stable"] as? String ?? "unknown"
                let installed = formulaData["installed"] as? [[String: Any]] ?? []

                result[name] = FormulaInfo(version: stable, isInstalled: !installed.isEmpty)
                
                if let fullName = formulaData["full_name"] as? String, fullName != name {
                    result[fullName] = FormulaInfo(version: stable, isInstalled: !installed.isEmpty)
                }
            }
        }
        return result
    } catch {
        print("Error getting batch formula info: \(error)")
        return [:]
    }
}

let formulae = searchFormulae(pattern: "^node(@[0-9]+)?$")
print("Parsed Formulae: \(formulae)")

let infos = getBatchFormulaeInfo(formulae)
print("Infos keys: \(infos.keys)")
print("Infos count: \(infos.count)")
