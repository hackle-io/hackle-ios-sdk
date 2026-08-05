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
            let result = RemoteConfigEvaluateResult.of(request: request, value: targetRule.value, reason: DecisionReason.TARGET_RULE_MATCH)
            return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
        }

        let result = RemoteConfigEvaluateResult.of(request: request, value: request.parameterConfig.defaultValue, reason: DecisionReason.DEFAULT_RULE)
        return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
    }
}
