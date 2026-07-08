import Foundation

typealias InAppMessageEligibilityLocalEvaluationFlow = EvaluationFlow<InAppMessageEligibilityLocalEvaluateRequest, InAppMessageEligibilityEvaluation>

protocol InAppMessageEligibilityLocalFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation?
}

extension InAppMessageEligibilityLocalFlowEvaluator {
    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let inAppMessageRequest = request as? InAppMessageEligibilityLocalEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityLocalEvaluateRequest)")
        }
        guard let inAppMessageNextFlow = nextFlow as? InAppMessageEligibilityLocalEvaluationFlow else {
            throw HackleError.error("Unsupported flow: \(type(of: nextFlow)) (expected: InAppMessageEligibilityLocalEvaluationFlow)")
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

/// Platform check
///
/// iOS를 지원안하면 UNSUPPORTED_PLATFORM
class PlatformInAppMessageEligibilityLocalFlowEvaluator: InAppMessageEligibilityLocalFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        guard request.inAppMessage.supports(platform: request.platformType) else {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.UNSUPPORTED_PLATFORM)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Specific User Check
///
/// 테스트 디바이스에서 사용
class OverrideInAppMessageEligibilityLocalFlowEvaluator: InAppMessageEligibilityLocalFlowEvaluator {
    private let userOverrideMatcher: InAppMessageUserOverrideMatcher

    init(userOverrideMatcher: InAppMessageUserOverrideMatcher) {
        self.userOverrideMatcher = userOverrideMatcher
    }

    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if try userOverrideMatcher.matches(request: request, context: context) {
            let result = InAppMessageEligibilityEvaluateResult.eligible(reason: DecisionReason.OVERRIDDEN)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Draft Check
///
/// 초안인지 확인
class DraftInAppMessageEligibilityLocalFlowEvaluator: InAppMessageEligibilityLocalFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if request.inAppMessageConfig.status == .draft {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.IN_APP_MESSAGE_DRAFT)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Pause Status Check
///
/// 진행중인지 확인
class PauseInAppMessageEligibilityLocalFlowEvaluator: InAppMessageEligibilityLocalFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if request.inAppMessageConfig.status == .pause {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.IN_APP_MESSAGE_PAUSED)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Target Check
///
/// IAM 타겟팅이 된 경우
class TargetInAppMessageEligibilityLocalFlowEvaluator: InAppMessageEligibilityLocalFlowEvaluator {
    private let targetMatcher: InAppMessageTargetMatcher

    init(targetMatcher: InAppMessageTargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        guard try targetMatcher.matches(request: request, context: context) else {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class LayoutResolveInAppMessageEligibilityLocalFlowEvaluator: InAppMessageEligibilityLocalFlowEvaluator {
    private let layoutEvaluator: InAppMessageLayoutLocalEvaluator

    init(layoutEvaluator: InAppMessageLayoutLocalEvaluator) {
        self.layoutEvaluator = layoutEvaluator
    }

    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        let layoutRequest = InAppMessageLayoutLocalEvaluateRequest.of(request: request)
        let layoutEvaluation: InAppMessageLayoutEvaluateResponse = try layoutEvaluator.evaluate(request: layoutRequest, context: Evaluators.context())
        context.set(layoutEvaluation)

        return try nextFlow.evaluate(request: request, context: context)
    }
}
