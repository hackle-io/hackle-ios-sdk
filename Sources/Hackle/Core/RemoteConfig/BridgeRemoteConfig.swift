//
//  BridgeRemoteConfig.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/18/25.
//

import Foundation


class BridgeRemoteConfig: RemoteConfigeCore, HackleRemoteConfig {
    let hackleAppContext: HackleAppContext

    init(user: User?, app: HackleCore, userManager: UserManager, hackleAppContext: HackleAppContext) {
        self.hackleAppContext = hackleAppContext
        super.init(user: user, app: app, userManager: userManager)
    }

    func getString(forKey: String, defaultValue: String) -> String {
        get(key: forKey, defaultValue: HackleValue(value: defaultValue)).value.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        get(key: forKey, defaultValue: HackleValue(value: defaultValue)).value.doubleOrNil?.toIntOrNil() ?? defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        get(key: forKey, defaultValue: HackleValue(value: defaultValue)).value.doubleOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        get(key: forKey, defaultValue: HackleValue(value: defaultValue)).value.boolOrNil ?? defaultValue
    }

    private func get(key: String, defaultValue: HackleValue) -> RemoteConfigDecision {
        get(key: key, defaultValue: defaultValue, hackleAppContext: self.hackleAppContext)
    }
}
