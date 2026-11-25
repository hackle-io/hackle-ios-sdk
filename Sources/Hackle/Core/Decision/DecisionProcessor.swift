import Foundation

protocol DecisionProcessor {

    func experiment(experimentKey: Experiment.Key, user: HackleUser) throws -> Decision

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)]

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision
}
