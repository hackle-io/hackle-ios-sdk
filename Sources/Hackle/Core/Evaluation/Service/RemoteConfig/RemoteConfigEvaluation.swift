//
//  RemoteConfigEvaluation.swift
//  Hackle
//

import Foundation

final class RemoteConfigEvaluation: Evaluation, Equatable {
    let parameter: RemoteConfigParameter
    let remoteConfigResult: RemoteConfigEvaluateResult
    let properties: [String: Any]

    var entity: Entity { parameter }
    var result: EvaluateResult { remoteConfigResult }

    init(entity: RemoteConfigParameter, result: RemoteConfigEvaluateResult, properties: [String: Any]) {
        self.parameter = entity
        self.remoteConfigResult = result
        self.properties = properties
    }

    static func ==(lhs: RemoteConfigEvaluation, rhs: RemoteConfigEvaluation) -> Bool {
        lhs.parameter.id == rhs.parameter.id
            && lhs.remoteConfigResult.valueId == rhs.remoteConfigResult.valueId
            && lhs.remoteConfigResult.value == rhs.remoteConfigResult.value
            && lhs.remoteConfigResult.reason == rhs.remoteConfigResult.reason
    }
}
