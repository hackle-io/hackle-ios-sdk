import Foundation


enum HackleValue: Codable, Equatable {

    case string(String)
    case int(Int64)
    case double(Double)
    case bool(Bool)
    case null

    init(value: Any) {
        if let value = Objects.asStringOrNil(value) {
            self = .string(value)
            return
        }

        if let value = Objects.asIntOrNull(value) {
            self = .int(value)
            return
        }

        if let value = Objects.asDoubleOrNil(value) {
            self = .double(value)
            return
        }

        if let value = Objects.asBoolOrNil(value) {
            self = .bool(value)
            return
        }

        self = .null
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }

        if let value = try? container.decode(Int64.self) {
            self = .int(value)
            return
        }

        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }

        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }

        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: return
        }
    }

    var type: HackleValueType {
        switch self {
        case .string: return .string
        case .int: return .number
        case .double: return .number
        case .bool: return .bool
        case .null: return .null
        }
    }
}

extension HackleValue {
    var rawValue: Any? {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .null: return nil
        }
    }
    var stringOrNil: String? {
        switch self {
        case .string(let value): return value
        case .int: return nil
        case .double: return nil
        case .bool: return nil
        case .null: return nil
        }
    }

    var intOrNil: Int64? {
        switch self {
        case .string: return nil
        case .int(let value): return value
        case .double(let value): return Int64(value)
        case .bool: return nil
        case .null: return nil
        }
    }

    var doubleOrNil: Double? {
        switch self {
        case .string: return nil
        case .int(let value): return Double(value)
        case .double(let value): return value
        case .bool: return nil
        case .null: return nil
        }
    }

    var boolOrNil: Bool? {
        switch self {
        case .string: return nil
        case .int: return nil
        case .double: return nil
        case .bool(let value): return value
        case .null: return nil
        }
    }
}

extension HackleValue {

    func asString() -> String? {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool: return nil
        case .null: return nil
        }
    }

    func asDouble() -> Double? {
        switch self {
        case .string(let value): return Double(value)
        case .int(let value): return Double(value)
        case .double(let value): return value
        case .bool: return nil
        case .null: return nil
        }
    }
    
    func asBool() -> Bool? {
        switch self {
        case .string(let value): return value.toBool()
        case .int(let value): return nil
        case .double(let value): return nil
        case .bool(let value): return value
        case .null: return nil
        }
    }

    func asVersion() -> Version? {
        Version.tryParse(value: rawValue)
    }
}

enum HackleValueType: String, Codable {
    case null = "NULL"
    case string = "STRING"
    case number = "NUMBER"
    case bool = "BOOLEAN"
    case version = "VERSION"
    case json = "JSON"
}

extension String {
    fileprivate func toBool() -> Bool? {
        guard count <= 5 else { return nil }
        
        switch lowercased() {
        case "true": return true
        case "false": return false
        default: return nil
        }
    }
}
