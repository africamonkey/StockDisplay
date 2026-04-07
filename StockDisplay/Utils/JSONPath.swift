import Foundation

enum JSONPathError: Error {
    case invalidPath
    case valueNotFound
    case typeMismatch
}

func extractValue(from json: Any, path: String) throws -> Any {
    var current: Any = json
    let components = path.split(separator: ".").map(String.init)
    
    for component in components {
        if component.contains("[") && component.contains("]") {
            let parts = component.split(separator: "[")
            let key = String(parts[0])
            let indexStr = parts[1].dropLast()
            guard let index = Int(indexStr) else {
                throw JSONPathError.invalidPath
            }
            guard let dict = current as? [String: Any],
                  let arr = dict[key] as? [Any],
                  index < arr.count else {
                throw JSONPathError.valueNotFound
            }
            current = arr[index]
        } else {
            guard let dict = current as? [String: Any],
                  let value = dict[component] else {
                throw JSONPathError.valueNotFound
            }
            current = value
        }
    }
    return current
}

func extractDouble(from json: Any, path: String) throws -> Double {
    let value = try extractValue(from: json, path: path)
    if let doubleValue = value as? Double {
        return doubleValue
    } else if let intValue = value as? Int {
        return Double(intValue)
    } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
        return doubleValue
    }
    throw JSONPathError.typeMismatch
}
