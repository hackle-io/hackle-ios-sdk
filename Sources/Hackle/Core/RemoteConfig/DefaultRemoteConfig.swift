//
//  DefaultRemoteConfig.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation


class DefaultRemoteConfig: HackleRemoteConfig {

    private let user: User?
    private let app: HackleCore
    private let userManager: UserManager

    init(user: User?, app: HackleCore, userManager: UserManager) {
        self.user = user
        self.app = app
        self.userManager = userManager
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
        let sample = TimerSample.start()
        let decision: RemoteConfigDecision
        do {
            let hackleUser = userManager.resolve(user: user)
            decision = try app.remoteConfig(parameterKey: key, user: hackleUser, defaultValue: defaultValue)
        } catch let error {
            Log.error("Unexpected exception while deciding remote config parameter[\(key)]. Returning default value: \(String(describing: error))")
            decision = RemoteConfigDecision(value: defaultValue, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.remoteConfig(sample: sample, key: key, decision: decision)
        return decision
    }
}
