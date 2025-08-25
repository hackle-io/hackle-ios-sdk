//
//  DefaultRemoteConfig.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation

class DefaultRemoteConfig: HackleRemoteConfig {
    private let hackleAppCore: HackleAppCore
    private let user: User?

    init(hackleAppCore: HackleAppCore, user: User?) {
        self.hackleAppCore = hackleAppCore
        self.user = user
    }

    func getString(forKey: String, defaultValue: String) -> String {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .default)
            .value.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .default)
            .value.doubleOrNil?.toIntOrNil() ?? defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .default)
            .value.doubleOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        hackleAppCore
            .remoteConfig(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .default)
            .value.boolOrNil ?? defaultValue
    }
}
