import Foundation

final class LocalDecisionProcessor: DecisionProcessor {

    private let workspaceFetcher: WorkspaceConfigFetcher
    private let evaluateProcessor: EvaluateProcessor

    init(workspaceFetcher: WorkspaceConfigFetcher, evaluateProcessor: EvaluateProcessor) {
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser) throws -> Decision {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return Decision.of(experiment: nil, variation: VariationKeys.control, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let experiment = workspace.getExperimentConfigOrNil(experimentKey: experimentKey) else {
            return Decision.of(experiment: nil, variation: VariationKeys.control, reason: DecisionReason.EXPERIMENT_NOT_FOUND)
        }

        let request = ExperimentLocalEvaluateRequest(
            workspace: workspace,
            entity: experiment,
            user: user,
            record: true
        )
        let response = try evaluateProcessor.experiment(request)
        return response.experimentEvaluation.toDecision()
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        var decisions = [(Experiment, Decision)]()
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return decisions
        }
        for experimentConfig in workspace.experimentConfigs {
            let request = ExperimentLocalEvaluateRequest(
                workspace: workspace,
                entity: experimentConfig,
                user: user,
                record: false
            )
            let response = try evaluateProcessor.experiment(request)
            decisions.append((experimentConfig, response.experimentEvaluation.toDecision()))
        }
        return decisions
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let featureFlag = workspace.getFeatureFlagConfigOrNil(featureKey: featureKey) else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.FEATURE_FLAG_NOT_FOUND)
        }

        let request = ExperimentLocalEvaluateRequest(
            workspace: workspace,
            entity: featureFlag,
            user: user,
            record: true
        )
        let response = try evaluateProcessor.experiment(request)
        return response.experimentEvaluation.toFeatureFlagDecision()
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

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let parameter = workspace.getRemoteConfigParameterConfigOrNil(parameterKey: parameterKey) else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.REMOTE_CONFIG_PARAMETER_NOT_FOUND)
        }

        let request = RemoteConfigLocalEvaluateRequest.of(
            workspace: workspace,
            entity: parameter,
            user: user,
            requiredType: defaultValue.type
        )
        let response = try evaluateProcessor.remoteConfig(request)
        return response.remoteConfigEvaluation.toDecision(requiredType: defaultValue.type, defaultValue: defaultValue)
    }
}
