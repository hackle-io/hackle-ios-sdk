import Foundation

typealias InAppMessageEligibilityFlow = EvaluationFlow<InAppMessageEligibilityRequest, InAppMessageEligibilityEvaluation>

protocol InAppMessageEligibilityFlowEvaluator: FlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation?
}

extension InAppMessageEligibilityFlowEvaluator {
    func evaluate<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, Evaluation>
    ) throws -> Evaluation? {
        guard let inAppMessageRequest = request as? InAppMessageEligibilityRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityRequest)")
        }

        guard let inAppMessageNextFlow = nextFlow as? InAppMessageEligibilityFlow else {
            throw HackleError.error("Unsupported flow: \(type(of: nextFlow)) (expected: InAppMessageEligibilityFlow)")
        }

        let inAppMessageEvaluation = try evaluateInAppMessage(request: inAppMessageRequest, context: context, nextFlow: inAppMessageNextFlow)

        if inAppMessageEvaluation == nil {
            return nil
        }

        guard let evaluation = inAppMessageEvaluation as? Evaluation else {
            throw HackleError.error("Unsupported evaluation: \(type(of: inAppMessageEvaluation)) (expected: \(Evaluation.self))")
        }

        return evaluation
    }
}

class PlatformInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        guard request.inAppMessage.supports(platform: .ios) else {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.UNSUPPORTED_PLATFORM)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class OverrideInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    private let userOverrideMatcher: InAppMessageMatcher

    init(userOverrideMatcher: InAppMessageMatcher) {
        self.userOverrideMatcher = userOverrideMatcher
    }

    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if try userOverrideMatcher.matches(request: request, context: context) {
            return InAppMessageEligibilityEvaluation.eligible(request: request, context: context, reason: DecisionReason.OVERRIDDEN)
        }

        return try nextFlow.evaluate(request: request, context: context)
    }
}

class DraftInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if request.inAppMessage.status == .draft {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_DRAFT)
        }

        return try nextFlow.evaluate(request: request, context: context)
    }
}
class PausedInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if request.inAppMessage.status == .pause {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_PAUSED)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class PeriodInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        guard request.inAppMessage.period.within(date: request.timestamp) else {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class TargetInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    private let targetMatcher: InAppMessageMatcher

    init(targetMatcher: InAppMessageMatcher) {
        self.targetMatcher = targetMatcher
    }

    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        guard try targetMatcher.matches(request: request, context: context) else {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
        }

        return try nextFlow.evaluate(request: request, context: context)
    }
}

class LayoutResolveInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    private let layoutEvaluator: Evaluator

    init(layoutEvaluator: Evaluator) {
        self.layoutEvaluator = layoutEvaluator
    }

    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        let layoutRequest = InAppMessageLayoutRequest.of(request: request)
        let layoutEvaluation: InAppMessageLayoutEvaluation = try layoutEvaluator.evaluate(request: layoutRequest, context: Evaluators.context())
        context.set(layoutEvaluation)

        return try nextFlow.evaluate(request: request, context: context)
    }
}

class FrequencyCapInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    private let frequencyCapMatcher: InAppMessageMatcher

    init(frequencyCapMatcher: InAppMessageMatcher) {
        self.frequencyCapMatcher = frequencyCapMatcher
    }

    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if try frequencyCapMatcher.matches(request: request, context: context) {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED)
        }

        return try nextFlow.evaluate(request: request, context: context)
    }
}

class HiddenInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    private let hiddenMatcher: InAppMessageMatcher

    init(hiddenMatcher: InAppMessageMatcher) {
        self.hiddenMatcher = hiddenMatcher
    }

    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if try hiddenMatcher.matches(request: request, context: context) {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_HIDDEN)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class EligibleInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        return InAppMessageEligibilityEvaluation.eligible(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_TARGET)
    }
}
