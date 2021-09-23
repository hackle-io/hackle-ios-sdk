import Foundation

class Enums {

    static func parseOrNil<E: RawRepresentable>(rawValue: E.RawValue) -> E? {
        guard let e = E(rawValue: rawValue) else {
            Log.debug("Unsupported type [\(rawValue)]. Please use the latest version of sdk.")
            return nil
        }
        return e
    }
}
