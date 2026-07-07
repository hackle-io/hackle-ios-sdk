import Foundation

class InAppMessageDeliverEvaluateResponse {
    let isEligible: Bool
    let code: InAppMessageDeliverResponse.Code?
    let evaluation: InAppMessageDeliverEvaluation?

    init(isEligible: Bool, code: InAppMessageDeliverResponse.Code?, evaluation: InAppMessageDeliverEvaluation?) {
        self.isEligible = isEligible
        self.code = code
        self.evaluation = evaluation
    }

    static func ineligible(code: InAppMessageDeliverResponse.Code) -> InAppMessageDeliverEvaluateResponse {
        return InAppMessageDeliverEvaluateResponse(isEligible: false, code: code, evaluation: nil)
    }

    static func of(evaluation: InAppMessageDeliverEvaluation) -> InAppMessageDeliverEvaluateResponse {
        if !evaluation.eligibility.eligibilityResult.isEligible {
            return ineligible(code: .ineligible)
        }
        return InAppMessageDeliverEvaluateResponse(isEligible: true, code: nil, evaluation: evaluation)
    }
}
