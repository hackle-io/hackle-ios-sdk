//
//  RemoteConfigEvaluation.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation


class RemoteConfigEvaluation: EvaluatorEvaluation, Equatable {

    let reason: String
    let targetEvaluations: [EvaluatorEvaluation]
    let parameter: RemoteConfigParameter
    let valueId: Int64?
    let value: HackleValue
    let properties: [String: Any]

    init(reason: String, targetEvaluations: [EvaluatorEvaluation], parameter: RemoteConfigParameter, valueId: Int64?, value: HackleValue, properties: [String: Any]) {
        self.reason = reason
        self.targetEvaluations = targetEvaluations
        self.parameter = parameter
        self.valueId = valueId
        self.value = value
        self.properties = properties
    }

    static func ==(lhs: RemoteConfigEvaluation, rhs: RemoteConfigEvaluation) -> Bool {
        lhs.parameter.id == rhs.parameter.id && lhs.valueId == rhs.valueId && lhs.value == rhs.value && lhs.reason == rhs.reason
    }

    static func of(
        request: RemoteConfigRequest,
        context: EvaluatorContext,
        valueId: Int64?,
        value: HackleValue,
        reason: String,
        properties: PropertiesBuilder
    ) -> RemoteConfigEvaluation {
        properties.add("returnValue", value.rawValue)
        return RemoteConfigEvaluation(
            reason: reason,
            targetEvaluations: context.targetEvaluations,
            parameter: request.parameter,
            valueId: valueId,
            value: value,
            properties: properties.build()
        )
    }

    static func ofDefault(
        request: RemoteConfigRequest,
        context: EvaluatorContext,
        reason: String,
        properties: PropertiesBuilder
    ) -> RemoteConfigEvaluation {
        of(
            request: request,
            context: context,
            valueId: nil,
            value: request.defaultValue,
            reason: reason,
            properties: properties
        )
    }
}