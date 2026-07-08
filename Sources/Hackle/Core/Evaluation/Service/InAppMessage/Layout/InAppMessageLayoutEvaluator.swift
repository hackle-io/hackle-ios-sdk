import Foundation

protocol InAppMessageLayoutEvaluator: LocalEvaluator where Request: InAppMessageLayoutEvaluateRequest, Response == InAppMessageLayoutEvaluateResponse {
}
