//
//  RemoteConfigProcessor.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/18/25.
//

class RemoteConfigProcessor {

    private let core: HackleCore
    private let userManager: UserManager

    init(core: HackleCore, userManager: UserManager) {
        self.core = core
        self.userManager = userManager
    }

    func get(key: String, defaultValue: HackleValue, user: User?, hackleAppContext: HackleAppContext) -> RemoteConfigDecision {
        let sample = TimerSample.start()
        let decision: RemoteConfigDecision
        do {
            let hackleUser = userManager.resolve(user: user, hackleAppContext: hackleAppContext)
            decision = try core.remoteConfig(parameterKey: key, user: hackleUser, defaultValue: defaultValue)
        } catch let error {
            Log.error("Unexpected exception while deciding remote config parameter[\(key)]. Returning default value: \(String(describing: error))")
            decision = RemoteConfigDecision(value: defaultValue, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.remoteConfig(sample: sample, key: key, decision: decision)
        return decision
    }
}
