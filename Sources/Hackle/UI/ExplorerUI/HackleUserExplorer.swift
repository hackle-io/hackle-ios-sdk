//
//  HackleUserExplorer.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation


protocol HackleUserExplorer {

    func currentUser() -> HackleUser

    func getAbTestDecisions() -> [(Experiment, Decision)]

    func getAbTestOverrides() -> [Int64: Int64]

    func setAbTestOverride(experiment: Experiment, variationId: Int64)

    func resetAbTestOverride(experiment: Experiment)

    func resetAllAbTestOverride()

    func getFeatureFlagDecisions() -> [(Experiment, FeatureFlagDecision)]

    func getFeatureFlagOverrides() -> [Int64: Int64]

    func setFeatureFlagOverride(experiment: Experiment, variationId: Int64)

    func resetFeatureFlagOverride(experiment: Experiment)

    func resetAllFeatureFlagOverride()
}

class DefaultHackleUserExplorer: HackleUserExplorer {

    private let core: HackleCore
    private let userManager: UserManager
    private let userResolver: HackleUserResolver
    private let abTestOverrideStorage: HackleUserManualOverrideStorage
    private let featureFlagOverrideStorage: HackleUserManualOverrideStorage

    init(core: HackleCore, userManager: UserManager, userResolver: HackleUserResolver, abTestOverrideStorage: HackleUserManualOverrideStorage, featureFlagOverrideStorage: HackleUserManualOverrideStorage) {
        self.core = core
        self.userManager = userManager
        self.userResolver = userResolver
        self.abTestOverrideStorage = abTestOverrideStorage
        self.featureFlagOverrideStorage = featureFlagOverrideStorage
    }

    func currentUser() -> HackleUser {
        let currentUser = userManager.currentUser
        return userResolver.resolve(user: currentUser)
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

    func setAbTestOverride(experiment: Experiment, variationId: Int64) {
        abTestOverrideStorage.set(experiment: experiment, variationId: variationId)
        increment(experimentType: .abTest, operation: "set")
    }

    func resetAbTestOverride(experiment: Experiment) {
        abTestOverrideStorage.remove(experiment: experiment)
        increment(experimentType: .abTest, operation: "reset")
    }

    func resetAllAbTestOverride() {
        abTestOverrideStorage.clear()
        increment(experimentType: .abTest, operation: "reset.all")
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

    func setFeatureFlagOverride(experiment: Experiment, variationId: Int64) {
        featureFlagOverrideStorage.set(experiment: experiment, variationId: variationId)
        increment(experimentType: .featureFlag, operation: "set")
    }

    func resetFeatureFlagOverride(experiment: Experiment) {
        featureFlagOverrideStorage.remove(experiment: experiment)
        increment(experimentType: .featureFlag, operation: "reset")
    }

    func resetAllFeatureFlagOverride() {
        featureFlagOverrideStorage.clear()
        increment(experimentType: .featureFlag, operation: "reset.all")
    }

    private func increment(experimentType: ExperimentType, operation: String) {
        let tags = [
            "experiment.type": experimentType.rawValue,
            "operation": operation
        ]
        Metrics.counter(name: "experiment.manual.override", tags: tags).increment()
    }
}
