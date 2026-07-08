//
//  RemoteConfigLocalEvaluator.swift
//  Hackle
//

import Foundation

final class RemoteConfigLocalEvaluator: LocalEvaluator, RemoteConfigEvaluator {

    typealias Request = RemoteConfigLocalEvaluateRequest
    typealias Response = RemoteConfigEvaluateResponse

    private let targetRuleDeterminer: RemoteConfigParameterTargetRuleDeterminer
    let eventRecorder: EvaluationEventRecorder

    init(targetRuleDeterminer: RemoteConfigParameterTargetRuleDeterminer, eventRecorder: EvaluationEventRecorder) {
        self.targetRuleDeterminer = targetRuleDeterminer
        self.eventRecorder = eventRecorder
    }

    func doEvaluate(request: RemoteConfigLocalEvaluateRequest, context: EvaluatorContext) throws -> RemoteConfigEvaluateResponse {
        if request.user.identifiers[request.parameterConfig.identifierType] == nil {
            let result = RemoteConfigEvaluateResult.of(reason: DecisionReason.IDENTIFIER_NOT_FOUND, value: nil)
            return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
        }

        if let targetRule = try targetRuleDeterminer.determine(request: request, context: context) {
            let result = self.result(request: request, value: targetRule.value, reason: DecisionReason.TARGET_RULE_MATCH)
            return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
        }

        let result = self.result(request: request, value: request.parameterConfig.defaultValue, reason: DecisionReason.DEFAULT_RULE)
        return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
    }

    private func result(
        request: RemoteConfigLocalEvaluateRequest,
        value: RemoteConfigParameter.Value,
        reason: String
    ) -> RemoteConfigEvaluateResult {
        if request.requiredType.isInstance(value) {
            return RemoteConfigEvaluateResult.of(reason: reason, value: value)
        } else {
            return RemoteConfigEvaluateResult.of(reason: DecisionReason.TYPE_MISMATCH, value: value)  // ★ TYPE_MISMATCH여도 value 유지 (의도된 wire 변경 ①)
        }
    }
}
