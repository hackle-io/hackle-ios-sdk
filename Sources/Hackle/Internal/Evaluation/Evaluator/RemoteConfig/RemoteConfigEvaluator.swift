//
//  RemoteConfigEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation


class RemoteConfigEvaluator: ContextualEvaluator {
    typealias Request = RemoteConfigRequest
    typealias Evaluation = RemoteConfigEvaluation

    private let remoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer

    init(remoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer) {
        self.remoteConfigTargetRuleDeterminer = remoteConfigTargetRuleDeterminer
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
        let propertiesBuilder = PropertiesBuilder()
            .add("requestValueType", request.defaultValue.type.rawValue)
            .add("requestDefaultValue", request.defaultValue.rawValue)

        if request.user.identifiers[request.parameter.identifierType] == nil {
            return RemoteConfigEvaluation.ofDefault(
                request: request,
                context: context,
                reason: DecisionReason.IDENTIFIER_NOT_FOUND,
                properties: propertiesBuilder
            )
        }

        if let targetRule = try remoteConfigTargetRuleDeterminer.determineTargetRuleOrNil(request: request, context: context) {
            propertiesBuilder.add("targetRuleKey", targetRule.key)
            propertiesBuilder.add("targetRuleName", targetRule.name)
            return evaluation(
                request: request,
                context: context,
                parameterValue: targetRule.value,
                reason: DecisionReason.TARGET_RULE_MATCH,
                propertiesBuilder: propertiesBuilder
            )
        }

        return evaluation(
            request: request,
            context: context,
            parameterValue: request.parameter.defaultValue,
            reason: DecisionReason.DEFAULT_RULE,
            propertiesBuilder: propertiesBuilder
        )
    }

    private func evaluation(
        request: Request,
        context: EvaluatorContext,
        parameterValue: RemoteConfigParameter.Value,
        reason: String,
        propertiesBuilder: PropertiesBuilder
    ) -> RemoteConfigEvaluation {
        if parameterValue.rawValue.type != request.defaultValue.type {
            return RemoteConfigEvaluation.ofDefault(
                request: request,
                context: context,
                reason: DecisionReason.TYPE_MISMATCH,
                properties: propertiesBuilder
            )
        } else {
            return RemoteConfigEvaluation.of(
                request: request,
                context: context,
                valueId: parameterValue.id,
                value: parameterValue.rawValue,
                reason: reason,
                properties: propertiesBuilder
            )
        }
    }
}
