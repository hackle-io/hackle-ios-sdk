//
//  DefaultRemoteConfig.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation

class DefaultRemoteConfig: HackleRemoteConfig {
    private let remoteConfigProcessor: RemoteConfigProcessor
    private let user: User?

    init(remoteConfigProcessor: RemoteConfigProcessor, user: User?) {
        self.remoteConfigProcessor = remoteConfigProcessor
        self.user = user
    }

    func getString(forKey: String, defaultValue: String) -> String {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .DEFAULT)
            .value.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .DEFAULT)
            .value.doubleOrNil?.toIntOrNil() ?? defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .DEFAULT)
            .value.doubleOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: .DEFAULT)
            .value.boolOrNil ?? defaultValue
    }
}
