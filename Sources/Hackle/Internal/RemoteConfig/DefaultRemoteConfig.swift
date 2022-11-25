//
//  DefaultRemoteConfig.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation


class DefaultRemoteConfig: HackleRemoteConfig {

    private let user: User
    private let app: HackleInternalApp
    private let userResolver: HackleUserResolver

    init(user: User, app: HackleInternalApp, userResolver: HackleUserResolver) {
        self.user = user
        self.app = app
        self.userResolver = userResolver
    }

    func getString(forKey: String, defaultValue: String) -> String {
        get(user: user, key: forKey, defaultValue: HackleValue(value: defaultValue)).value.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        get(user: user, key: forKey, defaultValue: HackleValue(value: defaultValue)).value.numberOrNil?.toIntOrNil() ?? defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        get(user: user, key: forKey, defaultValue: HackleValue(value: defaultValue)).value.numberOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        get(user: user, key: forKey, defaultValue: HackleValue(value: defaultValue)).value.boolOrNil ?? defaultValue
    }

    private func get(user: User, key: String, defaultValue: HackleValue) -> RemoteConfigDecision {
        do {
            guard let hackleUser = userResolver.resolveOrNil(user: user) else {
                return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.INVALID_INPUT)
            }
            return try app.remoteConfig(parameterKey: key, user: hackleUser, defaultValue: defaultValue)
        } catch let error {
            Log.error("Unexpected exception while deciding remote config parameter[\(key)]. Returning default value: \(String(describing: error))")
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.EXCEPTION)
        }
    }
}
