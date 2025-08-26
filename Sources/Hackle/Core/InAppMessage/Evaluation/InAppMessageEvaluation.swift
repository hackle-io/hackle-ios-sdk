import Foundation

class InAppMessageEvaluation {

    let isEligible: Bool
    let reason: String

    init(isEligible: Bool, reason: String) {
        self.isEligible = isEligible
        self.reason = reason
    }
}

extension InAppMessageEvaluation: CustomStringConvertible {
    var description: String {
        "InAppMessageEvaluation(isEligible: \(isEligible), reason: \(reason))"
    }

    static func from(evaluation: InAppMessageEligibilityEvaluation) -> InAppMessageEvaluation {
        return InAppMessageEvaluation(isEligible: evaluation.isEligible, reason: evaluation.reason)
    }
}
