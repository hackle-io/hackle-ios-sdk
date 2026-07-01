import Foundation

final class ExperimentEvaluateResult: EvaluateResult {
    let reason: String
    let variationId: Variation.Id?
    let variationKey: Variation.Key
    let config: ParameterConfiguration?

    init(reason: String, variationId: Variation.Id?, variationKey: Variation.Key, config: ParameterConfiguration?) {
        self.reason = reason
        self.variationId = variationId
        self.variationKey = variationKey
        self.config = config
    }

    func with(reason: String) -> ExperimentEvaluateResult {
        ExperimentEvaluateResult(
            reason: reason,
            variationId: variationId,
            variationKey: variationKey,
            config: config
        )
    }

    static func of(reason: String, variation: Variation, config: ParameterConfiguration?) -> ExperimentEvaluateResult {
        ExperimentEvaluateResult(
            reason: reason,
            variationId: variation.id,
            variationKey: variation.key,
            config: config
        )
    }

    static func ofDefault(reason: String, request: ExperimentLocalEvaluateRequest) throws -> ExperimentEvaluateResult {
        guard let variation = request.experiment.getVariationOrNil(variationKey: request.defaultVariationKey) else {
            return ExperimentEvaluateResult(
                reason: reason,
                variationId: nil,
                variationKey: request.defaultVariationKey,
                config: nil
            )
        }
        let config = try Self.config(workspace: request.workspace, variation: variation)
        return of(reason: reason, variation: variation, config: config)
    }

    private static func config(workspace: Workspace, variation: Variation) throws -> ParameterConfiguration? {
        guard let parameterConfigurationId = variation.parameterConfigurationId else {
            return nil
        }

        guard let parameterConfiguration = workspace.getParameterConfigurationOrNil(parameterConfigurationId: parameterConfigurationId) else {
            throw HackleError.error("ParameterConfiguration[\(parameterConfigurationId)]")
        }

        return parameterConfiguration
    }
}
