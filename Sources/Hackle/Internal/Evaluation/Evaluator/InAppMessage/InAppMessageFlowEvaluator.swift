//
//  InAppMessageFlowEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/06/26.
//

import Foundation

typealias InAppMessageFlow = EvaluationFlow<InAppMessageRequest, InAppMessageEvaluation>

protocol InAppMessageFlowEvaluator: FlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation?
}

extension InAppMessageFlowEvaluator {
    func evaluate<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, Evaluation>
    ) throws -> Evaluation? {
        guard let inAppMessageRequest = request as? InAppMessageRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageRequest)")
        }

        guard let inAppMessageNextFlow = nextFlow as? InAppMessageFlow else {
            throw HackleError.error("Unsupported flow: \(type(of: nextFlow)) (expected: InAppMessageFlow)")
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

extension InAppMessageResolver {
    func resolve(request: InAppMessageRequest, context: EvaluatorContext, reason: String) throws -> InAppMessageEvaluation {
        let message = try resolve(request: request, context: context)
        return InAppMessageEvaluation.of(request: request, context: context, reason: reason, message: message)
    }
}

class PlatformInAppMessageFlowEvaluator: InAppMessageFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation? {
        guard request.inAppMessage.supports(platform: .ios) else {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.UNSUPPORTED_PLATFORM)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class OverrideInAppMessageFlowEvaluator: InAppMessageFlowEvaluator {
    private let userOverrideMatcher: InAppMessageMatcher
    private let inAppMessageResolver: InAppMessageResolver

    init(userOverrideMatcher: InAppMessageMatcher, inAppMessageResolver: InAppMessageResolver) {
        self.userOverrideMatcher = userOverrideMatcher
        self.inAppMessageResolver = inAppMessageResolver
    }

    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation? {
        if try userOverrideMatcher.matches(request: request, context: context) {
            return try inAppMessageResolver.resolve(request: request, context: context, reason: DecisionReason.OVERRIDDEN)
        }

        return try nextFlow.evaluate(request: request, context: context)
    }
}

class DraftInAppMessageFlowEvaluator: InAppMessageFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation? {
        if request.inAppMessage.status == .draft {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_DRAFT)
        }

        return try nextFlow.evaluate(request: request, context: context)
    }
}

class PausedInAppMessageFlowEvaluator: InAppMessageFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation? {
        if request.inAppMessage.status == .pause {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_PAUSED)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class PeriodInAppMessageFlowEvaluator: InAppMessageFlowEvaluator {
    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation? {

        guard request.inAppMessage.period.within(date: request.timestamp) else {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class HiddenInAppMessageFlowEvaluator: InAppMessageFlowEvaluator {
    private let hiddenMatcher: InAppMessageMatcher

    init(hiddenMatcher: InAppMessageMatcher) {
        self.hiddenMatcher = hiddenMatcher
    }

    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation? {
        if try hiddenMatcher.matches(request: request, context: context) {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_HIDDEN)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class TargetInAppMessageFlowEvaluator: InAppMessageFlowEvaluator {

    private let targetMatcher: InAppMessageMatcher
    private let inAppMessageResolver: InAppMessageResolver

    init(targetMatcher: InAppMessageMatcher, inAppMessageResolver: InAppMessageResolver) {
        self.targetMatcher = targetMatcher
        self.inAppMessageResolver = inAppMessageResolver
    }

    func evaluateInAppMessage(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageFlow
    ) throws -> InAppMessageEvaluation? {

        if try targetMatcher.matches(request: request, context: context) {
            return try inAppMessageResolver.resolve(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_TARGET)
        }

        return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
    }
}
