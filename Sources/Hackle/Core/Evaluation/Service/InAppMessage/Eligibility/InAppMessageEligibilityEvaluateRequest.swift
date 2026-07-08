import Foundation

protocol InAppMessageEligibilityEvaluateRequest: EvaluateRequest {
    var inAppMessage: InAppMessage { get }
    var scope: InAppMessageEvaluateScope { get }
    var platformType: PlatformType { get }
    var timestamp: Date { get }
}
