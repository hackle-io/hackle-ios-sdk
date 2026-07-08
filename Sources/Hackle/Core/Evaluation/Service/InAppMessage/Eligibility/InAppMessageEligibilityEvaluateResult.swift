import Foundation

final class InAppMessageEligibilityEvaluateResult: EvaluateResult {
    let reason: String
    let isEligible: Bool

    init(reason: String, isEligible: Bool) {
        self.reason = reason
        self.isEligible = isEligible
    }

    static func eligible(reason: String) -> InAppMessageEligibilityEvaluateResult {
        InAppMessageEligibilityEvaluateResult(reason: reason, isEligible: true)
    }

    static func ineligible(reason: String) -> InAppMessageEligibilityEvaluateResult {
        InAppMessageEligibilityEvaluateResult(reason: reason, isEligible: false)
    }
}
