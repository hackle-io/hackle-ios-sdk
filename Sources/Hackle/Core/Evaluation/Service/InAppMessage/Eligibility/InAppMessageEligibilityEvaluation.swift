import Foundation

final class InAppMessageEligibilityEvaluation: Evaluation {
    let inAppMessage: InAppMessage
    let eligibilityResult: InAppMessageEligibilityEvaluateResult

    var entity: Entity { inAppMessage }
    var result: EvaluateResult { eligibilityResult }

    init(entity: InAppMessage, result: InAppMessageEligibilityEvaluateResult) {
        self.inAppMessage = entity
        self.eligibilityResult = result
    }
}
