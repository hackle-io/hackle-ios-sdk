import Foundation

final class LocalDecisionProcessor: DecisionProcessor {

    private let workspaceFetcher: WorkspaceConfigFetcher
    private let evaluateProcessor: EvaluateProcessor

    init(workspaceFetcher: WorkspaceConfigFetcher, evaluateProcessor: EvaluateProcessor) {
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision {
        guard let workspace = workspaceFetcher.fetch() else {
            return Decision.of(experiment: nil, variation: defaultVariationKey, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let experiment = workspace.getExperimentConfigOrNil(experimentKey: experimentKey) else {
            return Decision.of(experiment: nil, variation: defaultVariationKey, reason: DecisionReason.EXPERIMENT_NOT_FOUND)
        }

        let request = ExperimentLocalEvaluateRequest(
            workspace: workspace,
            entity: experiment,
            user: user,
            record: true,
            defaultVariationKey: defaultVariationKey
        )
        let response = try evaluateProcessor.experiment(request)
        return Decisions.toDecision(evaluation: response.experimentEvaluation)
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        var decisions = [(Experiment, Decision)]()
        guard let workspace = workspaceFetcher.fetch() else {
            return decisions
        }
        for experiment in workspace.experiments {
            guard let experimentConfig = workspace.getExperimentConfigOrNil(experimentKey: experiment.key) else {
                continue
            }
            let request = ExperimentLocalEvaluateRequest(
                workspace: workspace,
                entity: experimentConfig,
                user: user,
                record: false,
                defaultVariationKey: "A"
            )
            let response = try evaluateProcessor.experiment(request)
            decisions.append((experiment, Decisions.toDecision(evaluation: response.experimentEvaluation)))
        }
        return decisions
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        guard let workspace = workspaceFetcher.fetch() else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let featureFlag = workspace.getFeatureFlagConfigOrNil(featureKey: featureKey) else {
            return FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.FEATURE_FLAG_NOT_FOUND)
        }

        let request = ExperimentLocalEvaluateRequest(
            workspace: workspace,
            entity: featureFlag,
            user: user,
            record: true,
            defaultVariationKey: "A"
        )
        let response = try evaluateProcessor.experiment(request)
        return Decisions.toFeatureFlagDecision(evaluation: response.experimentEvaluation)
    }

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        var decisions = [(Experiment, FeatureFlagDecision)]()
        guard let workspace = workspaceFetcher.fetch() else {
            return decisions
        }
        for featureFlag in workspace.featureFlags {
            guard let featureFlagConfig = workspace.getFeatureFlagConfigOrNil(featureKey: featureFlag.key) else {
                continue
            }
            let request = ExperimentLocalEvaluateRequest(
                workspace: workspace,
                entity: featureFlagConfig,
                user: user,
                record: false,
                defaultVariationKey: "A"
            )
            let response = try evaluateProcessor.experiment(request)
            decisions.append((featureFlag, Decisions.toFeatureFlagDecision(evaluation: response.experimentEvaluation)))
        }
        return decisions
    }

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        guard let workspace = workspaceFetcher.fetch() else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.SDK_NOT_READY)
        }
        guard let parameter = workspace.getRemoteConfigParameterConfigOrNil(parameterKey: parameterKey) as? RemoteConfigParameter else {
            return RemoteConfigDecision(value: defaultValue, reason: DecisionReason.REMOTE_CONFIG_PARAMETER_NOT_FOUND)
        }

        let request = RemoteConfigLocalEvaluateRequest.of(
            workspace: workspace,
            parameter: parameter,
            user: user,
            defaultValue: defaultValue
        )
        let response = try evaluateProcessor.remoteConfig(request)
        return Decisions.toRemoteConfigDecision(evaluation: response.remoteConfigEvaluation)
    }
}
