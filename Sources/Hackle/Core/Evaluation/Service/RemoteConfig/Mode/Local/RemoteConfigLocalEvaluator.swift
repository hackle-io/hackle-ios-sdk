//
//  RemoteConfigLocalEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

final class RemoteConfigLocalEvaluator: RemoteConfigEvaluator {

    private let targetRuleDeterminer: RemoteConfigParameterTargetRuleDeterminer
    let eventRecorder: EvaluationEventRecorder

    init(targetRuleDeterminer: RemoteConfigParameterTargetRuleDeterminer, eventRecorder: EvaluationEventRecorder) {
        self.targetRuleDeterminer = targetRuleDeterminer
        self.eventRecorder = eventRecorder
    }

    func evaluateInternal(request: RemoteConfigLocalEvaluateRequest, context: EvaluatorContext) throws -> RemoteConfigEvaluateResponse {
        if request.user.identifiers[request.parameter.identifierType] == nil {
            let result = RemoteConfigEvaluateResult.of(reason: DecisionReason.IDENTIFIER_NOT_FOUND, value: request.defaultValue, valueId: nil)
            return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
        }

        if let targetRule = try targetRuleDeterminer.determine(request: request, context: context) {
            let result = self.result(request: request, value: targetRule.value, reason: DecisionReason.TARGET_RULE_MATCH)
            return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
        }

        let result = self.result(request: request, value: request.parameter.defaultValue, reason: DecisionReason.DEFAULT_RULE)
        return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
    }

    private func result(
        request: RemoteConfigLocalEvaluateRequest,
        value: RemoteConfigParameter.Value,
        reason: String
    ) -> RemoteConfigEvaluateResult {
        if value.rawValue.type == request.defaultValue.type {
            return RemoteConfigEvaluateResult.of(reason: reason, value: value.rawValue, valueId: value.id)
        } else {
            return RemoteConfigEvaluateResult.of(reason: DecisionReason.TYPE_MISMATCH, value: request.defaultValue, valueId: nil)
        }
    }
}
