import Foundation

extension Bundle {
    func hackleInfoString(forKey key: String) -> String? {
        infoDictionary?[key] as? String
    }

    func hackleInfoBool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        infoDictionary?[key] as? Bool ?? defaultValue
    }
}
