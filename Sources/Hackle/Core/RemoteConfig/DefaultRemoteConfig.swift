//
//  DefaultRemoteConfig.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation

class DefaultRemoteConfig: HackleRemoteConfig {
    private let hackleAppCore: HackleAppCore

    init(hackleAppCore: HackleAppCore) {
        self.hackleAppCore = hackleAppCore
    }

    func getString(forKey: String, defaultValue: String) -> String {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), hackleAppContext: .default)
            .value.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), hackleAppContext: .default)
            .value.doubleOrNil?.toIntOrNil() ?? defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), hackleAppContext: .default)
            .value.doubleOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), hackleAppContext: .default)
            .value.boolOrNil ?? defaultValue
    }
}
