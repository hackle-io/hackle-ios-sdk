import Foundation

final class LocalDevToolsDecisionProcessor: DevToolsDecisionProcessor {

    private let workspaceFetcher: WorkspaceConfigFetcher
    private let evaluateProcessor: EvaluateProcessor

    init(workspaceFetcher: WorkspaceConfigFetcher, evaluateProcessor: EvaluateProcessor) {
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
    }


    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        var decisions = [(Experiment, FeatureFlagDecision)]()
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return decisions
        }
        for featureFlagConfig in workspace.featureFlagConfigs {
            let request = ExperimentLocalEvaluateRequest(
                workspace: workspace,
                entity: featureFlagConfig,
                user: user,
                record: false
            )
            let response = try evaluateProcessor.experiment(request)
            decisions.append((featureFlagConfig, response.experimentEvaluation.toFeatureFlagDecision()))
        }
        return decisions
    }

    func remoteConfigs(user: HackleUser) throws -> [RemoteConfigEvaluation] {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return []
        }
        let parameters = workspace.remoteConfigParameters.compactMap { $0 as? RemoteConfigParameterConfig }
        return try parameters.map { parameter in
            let request = RemoteConfigLocalEvaluateRequest.of(
                workspace: workspace,
                entity: parameter,
                user: user,
                requiredType: parameter.type,
                record: false
            )
            return try evaluateProcessor.remoteConfig(request).remoteConfigEvaluation
        }
    }

    func inAppMessages(user: HackleUser, timestamp: Date) throws -> [InAppMessageEligibilityEvaluation] {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return []
        }
        let messages = workspace.inAppMessages.compactMap { $0 as? InAppMessageConfig }
        return try messages.map { inAppMessage in
            try evaluateProcessor.eligibility(
                workspace: workspace,
                inAppMessage: inAppMessage,
                user: user,
                scope: .trigger,
                timestamp: timestamp,
                record: false
            ).eligibilityEvaluation
        }
    }
}
