import Foundation

protocol InAppMessageLayoutEvaluator: ContextualEvaluator where Request: InAppMessageLayoutEvaluateRequest, Response == InAppMessageLayoutEvaluateResponse {
}
