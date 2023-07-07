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
}
