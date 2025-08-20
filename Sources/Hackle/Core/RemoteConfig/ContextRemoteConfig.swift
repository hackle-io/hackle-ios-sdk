//
//  ContextRemoteConfig.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/18/25.
//

import Foundation


class ContextRemoteConfig: HackleRemoteConfig {
    private let remoteConfigProcessor: RemoteConfigProcessor
    private let user: User?
    private let hackleAppContext: HackleAppContext

    init(remoteConfigProcessor: RemoteConfigProcessor, user: User?, hackleAppContext: HackleAppContext) {
        self.remoteConfigProcessor = remoteConfigProcessor
        self.user = user
        self.hackleAppContext = hackleAppContext
    }

    func getString(forKey: String, defaultValue: String) -> String {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: hackleAppContext)
            .value.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: hackleAppContext)
            .value.doubleOrNil?.toIntOrNil() ?? defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: hackleAppContext)
            .value.doubleOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        remoteConfigProcessor
            .get(key: forKey, defaultValue: HackleValue(value: defaultValue), user: user, hackleAppContext: hackleAppContext)
            .value.boolOrNil ?? defaultValue
    }
}
