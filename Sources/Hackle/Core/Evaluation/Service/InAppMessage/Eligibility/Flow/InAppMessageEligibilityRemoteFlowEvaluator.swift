import Foundation

typealias InAppMessageEligibilityRemoteEvaluationFlow = EvaluationFlow<InAppMessageEligibilityRemoteEvaluateRequest, InAppMessageEligibilityEvaluation>

protocol InAppMessageEligibilityRemoteFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityRemoteEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityRemoteEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation?
}

extension InAppMessageEligibilityRemoteFlowEvaluator {
    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let inAppMessageRequest = request as? InAppMessageEligibilityRemoteEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityRemoteEvaluateRequest)")
        }
        guard let inAppMessageNextFlow = nextFlow as? InAppMessageEligibilityRemoteEvaluationFlow else {
            throw HackleError.error("Unsupported flow: \(type(of: nextFlow)) (expected: InAppMessageEligibilityRemoteEvaluationFlow)")
        }
        let inAppMessageEvaluation = try evaluate(request: inAppMessageRequest, context: context, nextFlow: inAppMessageNextFlow)
        if inAppMessageEvaluation == nil {
            return nil
        }
        guard let evaluation = inAppMessageEvaluation as? E else {
            throw HackleError.error("Unsupported evaluation: \(type(of: inAppMessageEvaluation)) (expected: \(E.self))")
        }
        return evaluation
    }
}

/// Override check
///
/// 서버가 OVERRIDDEN으로 판단한 경우 eligible
class OverrideInAppMessageEligibilityRemoteFlowEvaluator: InAppMessageEligibilityRemoteFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityRemoteEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityRemoteEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if request.result.reason == DecisionReason.OVERRIDDEN {
            let result = InAppMessageEligibilityEvaluateResult.eligible(reason: DecisionReason.OVERRIDDEN)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Ineligible check
///
/// 서버가 ineligible로 판단한 경우 서버가 내린 reason 그대로 ineligible
class IneligibleInAppMessageEligibilityRemoteFlowEvaluator: InAppMessageEligibilityRemoteFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityRemoteEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityRemoteEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if !request.result.isEligible {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: request.result.reason)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator: InAppMessageEligibilityRemoteFlowEvaluator {
    private let layoutEvaluator: InAppMessageLayoutRemoteEvaluator

    init(layoutEvaluator: InAppMessageLayoutRemoteEvaluator) {
        self.layoutEvaluator = layoutEvaluator
    }

    func evaluate(
        request: InAppMessageEligibilityRemoteEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityRemoteEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        let layoutRequest = InAppMessageLayoutRemoteEvaluateRequest.of(request: request, inAppMessage: request.result.layout)
        let layoutResponse: InAppMessageLayoutEvaluateResponse = try layoutEvaluator.evaluate(request: layoutRequest, context: Evaluators.context())
        context.set(layoutResponse)

        return try nextFlow.evaluate(request: request, context: context)
    }
}
