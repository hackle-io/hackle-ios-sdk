import Foundation

protocol InAppMessageEligibilityEvaluator: LocalEvaluator where Request: InAppMessageEligibilityEvaluateRequest, Response == InAppMessageEligibilityEvaluateResponse {
}
