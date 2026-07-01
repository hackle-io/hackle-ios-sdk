import Foundation

struct InAppMessageDeliverEvaluation {
    let eligibility: InAppMessageEligibilityEvaluation
    let layout: InAppMessageLayoutEvaluateResponse

    func toProperties() -> [String: Any] {
        guard let experiment = layout.experiment else {
            return [:]
        }
        return PropertiesBuilder()
            .add("experiment_id", experiment.experiment.id)
            .add("experiment_key", experiment.experiment.key)
            .add("variation_id", experiment.experimentResult.variationId)
            .add("variation_key", experiment.experimentResult.variationKey)
            .add("experiment_decision_reason", experiment.experimentResult.reason)
            .build()
    }
}
