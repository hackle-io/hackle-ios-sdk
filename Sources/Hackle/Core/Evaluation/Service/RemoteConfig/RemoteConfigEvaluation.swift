//
//  RemoteConfigEvaluation.swift
//  Hackle
//

import Foundation

final class RemoteConfigEvaluation: Evaluation, Equatable {
    let parameter: RemoteConfigParameter
    let remoteConfigResult: RemoteConfigEvaluateResult

    var entity: Entity { parameter }
    var result: EvaluateResult { remoteConfigResult }

    init(entity: RemoteConfigParameter, result: RemoteConfigEvaluateResult) {
        self.parameter = entity
        self.remoteConfigResult = result
    }

    static func ==(lhs: RemoteConfigEvaluation, rhs: RemoteConfigEvaluation) -> Bool {
        lhs.parameter.id == rhs.parameter.id
            && lhs.remoteConfigResult.value?.id == rhs.remoteConfigResult.value?.id
            && lhs.remoteConfigResult.value?.rawValue == rhs.remoteConfigResult.value?.rawValue
            && lhs.remoteConfigResult.reason == rhs.remoteConfigResult.reason
    }
}
