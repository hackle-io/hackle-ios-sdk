import Foundation

protocol DevToolsDecisionProcessor {

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)]

    func remoteConfigs(user: HackleUser) throws -> [RemoteConfigEvaluation]

    func inAppMessages(user: HackleUser, timestamp: Date) throws -> [InAppMessageEligibilityEvaluation]
}
