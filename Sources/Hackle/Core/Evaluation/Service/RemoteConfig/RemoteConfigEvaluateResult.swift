import Foundation

final class RemoteConfigEvaluateResult: EvaluateResult {
    let reason: String
    let value: RemoteConfigParameter.Value?

    init(reason: String, value: RemoteConfigParameter.Value?) {
        self.reason = reason
        self.value = value
    }

    static func of(reason: String, value: RemoteConfigParameter.Value?) -> RemoteConfigEvaluateResult {
        RemoteConfigEvaluateResult(reason: reason, value: value)
    }
}
