//
//  RemoteConfigeCore.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/18/25.
//

open class RemoteConfigeCore {

    private let user: User?
    private let app: HackleCore
    private let userManager: UserManager

    init(user: User?, app: HackleCore, userManager: UserManager) {
        self.user = user
        self.app = app
        self.userManager = userManager
    }

    func get(key: String, defaultValue: HackleValue, hackleAppContext: HackleAppContext) -> RemoteConfigDecision {
        let sample = TimerSample.start()
        let decision: RemoteConfigDecision
        do {
            let hackleUser = userManager.resolve(user: user, hackleAppContext: hackleAppContext)
            decision = try app.remoteConfig(parameterKey: key, user: hackleUser, defaultValue: defaultValue)
        } catch let error {
            Log.error("Unexpected exception while deciding remote config parameter[\(key)]. Returning default value: \(String(describing: error))")
            decision = RemoteConfigDecision(value: defaultValue, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.remoteConfig(sample: sample, key: key, decision: decision)
        return decision
    }
}
