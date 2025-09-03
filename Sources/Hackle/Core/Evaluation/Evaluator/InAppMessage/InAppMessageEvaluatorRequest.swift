import Foundation

protocol InAppMessageEvaluatorRequest: EvaluatorRequest {
    var workspace: Workspace { get }
    var user: HackleUser { get }
    var inAppMessage: InAppMessage { get }
}

extension InAppMessageEvaluatorRequest {
    var key: EvaluatorKey {
        return EvaluatorKey(type: .inAppMessage, id: inAppMessage.id)
    }
}
