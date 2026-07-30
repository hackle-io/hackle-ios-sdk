import Foundation

class RemoteConfigEvaluateResult: EvaluateResult {
    let reason: String
    let value: RemoteConfigParameter.Value?

    init(reason: String, value: RemoteConfigParameter.Value?) {
        self.reason = reason
        self.value = value
    }

    static func of(reason: String, value: RemoteConfigParameter.Value?) -> RemoteConfigEvaluateResult {
        RemoteConfigEvaluateResult(reason: reason, value: value)
    }

    static func of(
        request: RemoteConfigEvaluateRequest,
        value: RemoteConfigParameter.Value?,
        reason: String
    ) -> RemoteConfigEvaluateResult {
        guard let value = value else {
            return of(reason: reason, value: nil)
        }
        if request.requiredType.isInstance(value) {
            return of(reason: reason, value: value)
        } else {
            return of(reason: DecisionReason.TYPE_MISMATCH, value: value)  // TYPE_MISMATCH여도 value 유지
        }
    }
}
