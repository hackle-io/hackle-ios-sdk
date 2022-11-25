import Foundation


enum HackleValue: Codable, Equatable {

    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(value: Any) {
        if let value = Objects.asStringOrNil(value) {
            self = .string(value)
            return
        }

        if let value = Objects.asDoubleOrNil(value) {
            self = .number(value)
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

        if let value = try? container.decode(Double.self) {
            self = .number(value)
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
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: return
        }
    }

    var stringOrNil: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }

    var numberOrNil: Double? {
        switch self {
        case .number(let value):
            return value
        default:
            return nil
        }
    }

    var boolOrNil: Bool? {
        switch self {
        case .bool(let value):
            return value
        default:
            return nil
        }
    }

    var rawValue: Any? {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .bool(let value):
            return value
        case .null:
            return nil
        }
    }

    var type: HackleValueType {
        switch self {
        case .string: return .string
        case .number: return .number
        case .bool: return .bool
        case .null: return .null
        }
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