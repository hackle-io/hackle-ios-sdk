import Foundation

protocol InAppMessageEligibilityEvaluator: ContextualEvaluator where Request: InAppMessageEligibilityEvaluateRequest, Response == InAppMessageEligibilityEvaluateResponse {
}

extension InAppMessageEligibilityEvaluator {

    /// eligibility 평가는 ineligible이어도 함께 평가된 layout을 기록한다.
    /// 시그니처는 Evaluator.record requirement와 동일해야 witness로 선택된다.
    func record(request: EvaluateRequest, response: EvaluateResponse) {
        eventRecorder.record(response: response)
        guard let eligibilityResponse = response as? InAppMessageEligibilityEvaluateResponse else {
            return
        }
        if !eligibilityResponse.eligibilityEvaluation.eligibilityResult.isEligible, let layout = eligibilityResponse.layout {
            eventRecorder.record(response: layout)
        }
    }
}
