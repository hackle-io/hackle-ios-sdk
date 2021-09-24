import Foundation


enum MatchValue: Codable, Equatable {

    case string(String)
    case number(Double)
    case bool(Bool)
    case other

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

        self = .other
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

        self = .other
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .other: return
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
}
