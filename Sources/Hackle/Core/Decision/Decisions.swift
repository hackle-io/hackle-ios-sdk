import Foundation

enum Decisions {

    static func toDecision(evaluation: ExperimentEvaluation) -> Decision {
        let result = evaluation.experimentResult
        let config: ParameterConfig = result.config ?? EmptyParameterConfig.instance
        return Decision.of(
            experiment: evaluation.experiment,
            variation: result.variationKey,
            reason: result.reason,
            config: config
        )
    }

    static func toFeatureFlagDecision(evaluation: ExperimentEvaluation) -> FeatureFlagDecision {
        let result = evaluation.experimentResult
        let config: ParameterConfig = result.config ?? EmptyParameterConfig.instance
        return result.variationKey == "A"
            ? FeatureFlagDecision.off(featureFlag: evaluation.experiment, reason: result.reason, config: config)
            : FeatureFlagDecision.on(featureFlag: evaluation.experiment, reason: result.reason, config: config)
    }

    static func toRemoteConfigDecision(evaluation: RemoteConfigEvaluation) -> RemoteConfigDecision {
        let result = evaluation.remoteConfigResult
        return RemoteConfigDecision(value: result.value, reason: result.reason)
    }
}
