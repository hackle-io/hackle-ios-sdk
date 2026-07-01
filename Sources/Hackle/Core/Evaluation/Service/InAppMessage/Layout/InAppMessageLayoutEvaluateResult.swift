import Foundation

final class InAppMessageLayoutEvaluateResult: EvaluateResult {
    let reason: String
    let message: InAppMessage.Message

    init(reason: String, message: InAppMessage.Message) {
        self.reason = reason
        self.message = message
    }

    static func of(reason: String, message: InAppMessage.Message) -> InAppMessageLayoutEvaluateResult {
        InAppMessageLayoutEvaluateResult(reason: reason, message: message)
    }
}
