import Foundation

protocol InAppMessageEligibilityEvaluator: ContextualEvaluator where Request: InAppMessageEligibilityEvaluateRequest, Response == InAppMessageEligibilityEvaluateResponse {
}
