import Foundation

final class RemoteConfigParameterRemoteEvaluateResult: RemoteConfigEvaluateResult, RemoteConfigParameter, RemoteEvaluateResult, @unchecked Sendable {

    let id: RemoteConfigParameter.Id
    let key: RemoteConfigParameter.Key
    let type: HackleValueType
    let references: [Entity]

    init(
        id: RemoteConfigParameter.Id,
        key: RemoteConfigParameter.Key,
        type: HackleValueType,
        value: RemoteConfigParameter.Value?,
        reason: String,
        references: [Entity]
    ) {
        self.id = id
        self.key = key
        self.type = type
        self.references = references
        super.init(reason: reason, value: value)
    }

    func toEvaluation() -> Evaluation {
        RemoteConfigEvaluation(entity: self, result: self)
    }
}
