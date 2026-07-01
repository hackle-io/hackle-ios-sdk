import Foundation

protocol DecisionProcessor {

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)]

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision
}
