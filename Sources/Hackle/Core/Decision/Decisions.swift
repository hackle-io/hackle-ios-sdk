import Foundation

enum Decisions {

    static func toDecision(evaluation: ExperimentEvaluation) -> Decision {
        let result = evaluation.experimentResult
        let config: ParameterConfig = result.variation.parameterConfiguration ?? EmptyParameterConfig.instance
        return Decision.of(
            experiment: evaluation.experiment,
            variation: result.variation.key,
            reason: result.reason,
            config: config
        )
    }

    static func toFeatureFlagDecision(evaluation: ExperimentEvaluation) -> FeatureFlagDecision {
        let result = evaluation.experimentResult
        let config: ParameterConfig = result.variation.parameterConfiguration ?? EmptyParameterConfig.instance
        return result.variation.key == "A"
            ? FeatureFlagDecision.off(featureFlag: evaluation.experiment, reason: result.reason, config: config)
            : FeatureFlagDecision.on(featureFlag: evaluation.experiment, reason: result.reason, config: config)
    }

    static func toRemoteConfigDecision(evaluation: RemoteConfigEvaluation, requiredType: HackleValueType, defaultValue: HackleValue) -> RemoteConfigDecision {
        let result = evaluation.remoteConfigResult
        guard let value = result.value, let typedValue = requiredType.cast(value) else {
            return RemoteConfigDecision(value: defaultValue, reason: result.reason)
        }
        return RemoteConfigDecision(value: typedValue, reason: result.reason)
    }
}
