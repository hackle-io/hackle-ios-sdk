import Foundation

final class RemoteConfigEvaluateResult: EvaluateResult {
    let reason: String
    let value: HackleValue
    let valueId: Int64?

    init(reason: String, value: HackleValue, valueId: Int64?) {
        self.reason = reason
        self.value = value
        self.valueId = valueId
    }

    static func of(reason: String, value: HackleValue, valueId: Int64?) -> RemoteConfigEvaluateResult {
        RemoteConfigEvaluateResult(reason: reason, value: value, valueId: valueId)
    }
}
