import Foundation

class Enums {
    static func parseOrNil<E: RawRepresentable>(rawValue: E.RawValue) -> E? {
        guard let e = E(rawValue: rawValue) else {
            Log.debug("Unsupported type [\(rawValue)]. Please use the latest version of sdk.")
            return nil
        }
        return e
    }

    static func parseAllOrNil<E: RawRepresentable>(_ rawValues: [E.RawValue]) -> [E]? {
        var values = [E]()
        for rawValue in rawValues {
            guard let value: E = parseOrNil(rawValue: rawValue) else {
                return nil
            }
            values.append(value)
        }
        return values
    }

    static func parse<E: RawRepresentable>(rawValue: E.RawValue) throws -> E {
        guard let e = E(rawValue: rawValue) else {
            throw HackleError.error("Unsupported \(E.self) [\(rawValue)]")
        }
        return e
    }

    static func parseAll<E: RawRepresentable>(_ rawValues: [E.RawValue]) throws -> [E] {
        return try rawValues.map { try Enums.parse(rawValue: $0) }
    }
}
