import Foundation
@testable import Hackle


class MemoryKeyValueRepository: KeyValueRepository {

    private var dict: [String: Any]

    init(dict: [String: Any] = [:]) {
        self.dict = dict
    }

    func getString(key: String) -> String? {
        dict[key] as? String
    }

    func putString(key: String, value: String) {
        dict[key] = value
    }

    func getDouble(key: String) -> Double {
        dict[key] as? Double ?? 0.0
    }

    func putDouble(key: String, value: Double) {
        dict[key] = value
    }

    func putData(key: String, value: Data) {
        dict[key] = value
    }

    func getData(key: String) -> Data? {
        dict[key] as? Data
    }
}