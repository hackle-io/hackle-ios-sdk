import Foundation

final class RemoteDevToolsDecisionProcessor: DevToolsDecisionProcessor {

    private let workspaceFetcher: WorkspaceEvaluationFetcher
    private let evaluateProcessor: EvaluateProcessor

    init(workspaceFetcher: WorkspaceEvaluationFetcher, evaluateProcessor: EvaluateProcessor) {
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
    }


    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        var decisions = [(Experiment, FeatureFlagDecision)]()
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return decisions
        }
        for featureFlag in workspace.featureFlagResults {
            let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: featureFlag, user: user, record: false)
            let response = try evaluateProcessor.experiment(request)
            decisions.append((featureFlag, response.experimentEvaluation.toFeatureFlagDecision()))
        }
        return decisions
    }

    func remoteConfigs(user: HackleUser) throws -> [RemoteConfigEvaluation] {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return []
        }
        return try workspace.remoteConfigParameterResults.map { parameter in
            let request = RemoteConfigRemoteEvaluateRequest.of(
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
        return try workspace.inAppMessageResults.map { inAppMessage in
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
