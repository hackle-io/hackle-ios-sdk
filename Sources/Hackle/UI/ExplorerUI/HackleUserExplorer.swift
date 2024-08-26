//
//  HackleUserExplorer.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation


protocol HackleUserExplorer {

    func currentUser() -> HackleUser

    func registeredPushToken() -> String?

    func getAbTestDecisions() -> [(Experiment, Decision)]

    func getAbTestOverrides() -> [Int64: Int64]

    func setAbTestOverride(experiment: Experiment, variation: Variation)

    func resetAbTestOverride(experiment: Experiment, variation: Variation)

    func resetAllAbTestOverride()

    func getFeatureFlagDecisions() -> [(Experiment, FeatureFlagDecision)]

    func getFeatureFlagOverrides() -> [Int64: Int64]

    func setFeatureFlagOverride(experiment: Experiment, variation: Variation)

    func resetFeatureFlagOverride(experiment: Experiment, variation: Variation)

    func resetAllFeatureFlagOverride()
}

class DefaultHackleUserExplorer: HackleUserExplorer {

    private let core: HackleCore
    private let userManager: UserManager
    private let pushTokenManager: PushTokenManager
    private let abTestOverrideStorage: HackleUserManualOverrideStorage
    private let featureFlagOverrideStorage: HackleUserManualOverrideStorage
    private let devToolsAPI: DevToolsAPI

    init(
        core: HackleCore,
        userManager: UserManager,
        pushTokenManager: PushTokenManager,
        abTestOverrideStorage: HackleUserManualOverrideStorage,
        featureFlagOverrideStorage: HackleUserManualOverrideStorage,
        devToolsAPI: DevToolsAPI
    ) {
        self.core = core
        self.userManager = userManager
        self.pushTokenManager = pushTokenManager
        self.abTestOverrideStorage = abTestOverrideStorage
        self.featureFlagOverrideStorage = featureFlagOverrideStorage
        self.devToolsAPI = devToolsAPI
    }

    func currentUser() -> HackleUser {
        userManager.resolve(user: nil)
    }

    func registeredPushToken() -> String? {
        pushTokenManager.currentToken()?.value
    }

    func getAbTestDecisions() -> [(Experiment, Decision)] {
        do {
            return try core.experiments(user: currentUser())
        } catch {
            return []
        }
    }

    func getAbTestOverrides() -> [Int64: Int64] {
        abTestOverrideStorage.getAll()
    }

    func setAbTestOverride(experiment: Experiment, variation: Variation) {
        abTestOverrideStorage.set(experiment: experiment, variationId: variation.id)
        increment(experimentType: .abTest, operation: "set")

        devToolsAPI.addExperimentOverrides(experimentKey: experiment.key, request: createOverrideRequest(variation: variation))
    }

    func resetAbTestOverride(experiment: Experiment, variation: Variation) {
        abTestOverrideStorage.remove(experiment: experiment)
        increment(experimentType: .abTest, operation: "reset")

        devToolsAPI.removeExperimentOverrides(experimentKey: experiment.key, request: createOverrideRequest(variation: variation))
    }

    func resetAllAbTestOverride() {
        abTestOverrideStorage.clear()
        increment(experimentType: .abTest, operation: "reset.all")

        devToolsAPI.removeAllExperimentOverrides(request: createOverrideRequest())
    }

    func getFeatureFlagDecisions() -> [(Experiment, FeatureFlagDecision)] {
        do {
            return try core.featureFlags(user: currentUser())
        } catch {
            return []
        }
    }

    func getFeatureFlagOverrides() -> [Int64: Int64] {
        featureFlagOverrideStorage.getAll()
    }

    func setFeatureFlagOverride(experiment: Experiment, variation: Variation) {
        featureFlagOverrideStorage.set(experiment: experiment, variationId: variation.id)
        increment(experimentType: .featureFlag, operation: "set")

        devToolsAPI.addFeatureFlagOverrides(experimentKey: experiment.key, request: createOverrideRequest(variation: variation))
    }

    func resetFeatureFlagOverride(experiment: Experiment, variation: Variation) {
        featureFlagOverrideStorage.remove(experiment: experiment)
        increment(experimentType: .featureFlag, operation: "reset")

        devToolsAPI.removeFeatureFlagOverrides(experimentKey: experiment.key, request: createOverrideRequest(variation: variation))
    }

    func resetAllFeatureFlagOverride() {
        featureFlagOverrideStorage.clear()
        increment(experimentType: .featureFlag, operation: "reset.all")

        devToolsAPI.removeAllFeatureFlagOverrides(request: createOverrideRequest())
    }

    private func createOverrideRequest(variation: Variation? = nil) -> OverrideRequest {
        let hackleUser = currentUser()
        let user = userManager.currentUser.toBuilder()
            .id(hackleUser.id)
            .deviceId(hackleUser.deviceId)
            .userId(hackleUser.userId)
            .properties(hackleUser.properties)
            .build()
        return OverrideRequest(user: user, variation: variation)
    }

    private func increment(experimentType: ExperimentType, operation: String) {
        let tags = [
            "experiment.type": experimentType.rawValue,
            "operation": operation
        ]
        Metrics.counter(name: "experiment.manual.override", tags: tags).increment()
    }
}
