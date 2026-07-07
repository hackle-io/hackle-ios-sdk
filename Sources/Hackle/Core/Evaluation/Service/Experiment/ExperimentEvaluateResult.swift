import Foundation

final class ExperimentEvaluateResult: EvaluateResult, CustomStringConvertible {
    let reason: String
    let variation: Variation

    var description: String {
        "ExperimentEvaluateResult(reason: \(reason), variation: \(variation))"
    }

    init(reason: String, variation: Variation) {
        self.reason = reason
        self.variation = variation
    }

    func with(reason: String) -> ExperimentEvaluateResult {
        ExperimentEvaluateResult(reason: reason, variation: variation)
    }

    static func of(reason: String, variation: Variation) -> ExperimentEvaluateResult {
        ExperimentEvaluateResult(reason: reason, variation: variation)
    }

    // java: ofControl(reason, request) = of(reason, request.entity.controlVariation)
    static func ofControl(reason: String, request: ExperimentLocalEvaluateRequest) throws -> ExperimentEvaluateResult {
        of(reason: reason, variation: try request.experimentConfig.controlVariation)
    }
}
