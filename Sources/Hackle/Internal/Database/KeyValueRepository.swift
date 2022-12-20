//
//  KeyValueRepository.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation

protocol KeyValueRepository {

    func getString(key: String) -> String?

    func putString(key: String, value: String)

    func getDouble(key: String) -> Double

    func putDouble(key: String, value: Double)
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

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func getString(key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    func putString(key: String, value: String) {
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
}
