import Foundation

final class RemoteDecisionProcessor: DecisionProcessor {

    private let workspaceFetcher: WorkspaceEvaluationFetcher
    private let evaluateProcessor: EvaluateProcessor

    init(workspaceFetcher: WorkspaceEvaluationFetcher, evaluateProcessor: EvaluateProcessor) {
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser) throws -> Decision {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return Decision.of(experiment: nil, variation: "A", reason: DecisionReason.SDK_NOT_READY)
        }
        guard let experiment = workspace.getExperimentResultOrNil(experimentKey: experimentKey) else {
            return Decision.of(experiment: nil, variation: "A", reason: DecisionReason.EXPERIMENT_NOT_FOUND)
        }

        let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: experiment, user: user)
        let response = try evaluateProcessor.experiment(request)
        return response.experimentEvaluation.toDecision()
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        var decisions = [(Experiment, Decision)]()
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return decisions
        }
        for experiment in workspace.experimentResults {
            let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: experiment, user: user, record: false)
            let response = try evaluateProcessor.experiment(request)
            decisions.append((experiment, response.experimentEvaluation.toDecision()))
        }
        return decisions
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let featureFlag = workspace.getFeatureFlagResultOrNil(featureKey: featureKey) else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.FEATURE_FLAG_NOT_FOUND)
        }

        let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: featureFlag, user: user)
        let response = try evaluateProcessor.experiment(request)
        return response.experimentEvaluation.toFeatureFlagDecision()
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

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let parameter = workspace.getRemoteConfigParameterResultOrNil(parameterKey: parameterKey) else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.REMOTE_CONFIG_PARAMETER_NOT_FOUND)
        }

        let request = RemoteConfigRemoteEvaluateRequest.of(workspace: workspace, entity: parameter, user: user, requiredType: defaultValue.type)
        let response = try evaluateProcessor.remoteConfig(request)
        return response.remoteConfigEvaluation.toDecision(requiredType: defaultValue.type, defaultValue: defaultValue)
    }
}
