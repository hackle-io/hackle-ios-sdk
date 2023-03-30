//
//  KeyValueRepository.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation

protocol KeyValueRepository {

    func getAll() -> [String: Any]

    func getString(key: String) -> String?

    func putString(key: String, value: String)

    func getInteger(key: String) -> Int

    func putInteger(key: String, value: Int)

    func getDouble(key: String) -> Double

    func putDouble(key: String, value: Double)

    func getData(key: String) -> Data?

    func putData(key: String, value: Data)

    func remove(key: String)

    func clear()
}

extension KeyValueRepository {
    func getString(key: String, mapping: (String) -> String) -> String {
        guard let value = getString(key: key) else {
            let newValue = mapping(key)
            putString(key: key, value: newValue)
            return newValue
        }
        return value
    }
}

class UserDefaultsKeyValueRepository: KeyValueRepository {

    private let userDefaults: UserDefaults
    private let suiteName: String?

    init(userDefaults: UserDefaults, suiteName: String?) {
        self.userDefaults = userDefaults
        self.suiteName = suiteName
    }

    static func of(suiteName: String) -> UserDefaultsKeyValueRepository {
        UserDefaultsKeyValueRepository(userDefaults: UserDefaults(suiteName: suiteName)!, suiteName: suiteName)
    }

    func getAll() -> [String: Any] {
        userDefaults.dictionaryRepresentation()
    }

    func getString(key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    func putString(key: String, value: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func getInteger(key: String) -> Int {
        userDefaults.integer(forKey: key)
    }

    func putInteger(key: String, value: Int) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func getDouble(key: String) -> Double {
        userDefaults.double(forKey: key)
    }

    func putDouble(key: String, value: Double) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func getData(key: String) -> Data? {
        userDefaults.data(forKey: key)
    }

    func putData(key: String, value: Data) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    func remove(key: String) {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }

    func clear() {
        guard let suiteName = suiteName else {
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
    }
}
