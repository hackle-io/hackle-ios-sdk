import Foundation
@testable import Hackle

final class DevToolsDecisionProcessorStub: DecisionProcessor, DevToolsDecisionProcessor {
    var experiments = [(Experiment, Decision)]()
    var featureFlags = [(Experiment, FeatureFlagDecision)]()

    func experiment(experimentKey: Experiment.Key, user: HackleUser) throws -> Decision {
        throw HackleError.error("unused")
    }
    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] { experiments }
    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        throw HackleError.error("unused")
    }
    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        throw HackleError.error("unused")
    }
    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] { featureFlags }
    func remoteConfigs(user: HackleUser) throws -> [RemoteConfigEvaluation] { [] }
    func inAppMessages(user: HackleUser, timestamp: Date) throws -> [InAppMessageEligibilityEvaluation] { [] }
}
