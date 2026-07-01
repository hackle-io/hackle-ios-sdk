import Foundation

protocol InAppMessageLayoutEvaluateResult: EvaluateResult {
    var message: InAppMessage.Message { get }
}

extension InAppMessageLayoutEvaluateResult {
    static func of(reason: String, message: InAppMessage.Message) -> InAppMessageLayoutEvaluateResult {
        DefaultInAppMessageLayoutEvaluateResult(reason: reason, message: message)
    }
}

private final class DefaultInAppMessageLayoutEvaluateResult: InAppMessageLayoutEvaluateResult {
    let reason: String
    let message: InAppMessage.Message

    init(reason: String, message: InAppMessage.Message) {
        self.reason = reason
        self.message = message
    }
}
