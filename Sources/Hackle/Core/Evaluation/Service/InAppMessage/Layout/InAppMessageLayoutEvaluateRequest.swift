import Foundation

protocol InAppMessageLayoutEvaluateRequest: EvaluateRequest {
    var inAppMessage: InAppMessage { get }
    var scope: InAppMessageEvaluateScope { get }
}
