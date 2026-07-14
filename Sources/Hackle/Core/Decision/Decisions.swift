import Foundation

// java-core decision/Decisions 대응 — receiver extension 형태
extension ExperimentEvaluation {

    func toDecision() -> Decision {
        let result = experimentResult
        let config: ParameterConfig = result.variation.parameterConfiguration ?? EmptyParameterConfig.instance
        return Decision.of(
            experiment: experiment,
            variation: result.variation.key,
            reason: result.reason,
            config: config
        )
    }

    func toFeatureFlagDecision() -> FeatureFlagDecision {
        let result = experimentResult
        let config: ParameterConfig = result.variation.parameterConfiguration ?? EmptyParameterConfig.instance
        return result.variation.key == "A"
            ? FeatureFlagDecision.off(featureFlag: experiment, reason: result.reason, config: config)
            : FeatureFlagDecision.on(featureFlag: experiment, reason: result.reason, config: config)
    }
}

extension RemoteConfigEvaluation {

    func toDecision(requiredType: HackleValueType, defaultValue: HackleValue) -> RemoteConfigDecision {
        let result = remoteConfigResult
        guard let value = result.value, let typedValue = requiredType.cast(value) else {
            return RemoteConfigDecision(value: defaultValue, reason: result.reason)
        }
        return RemoteConfigDecision(value: typedValue, reason: result.reason)
    }
}
