//
//  InAppMessageEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation

class InAppMessageEvaluator: ContextualEvaluator {

    typealias Request = InAppMessageRequest
    typealias Evaluation = InAppMessageEvaluation

    private let userOverrideMatcher: InAppMessageMatcher
    private let hiddenMatcher: InAppMessageMatcher
    private let targetMatcher: InAppMessageMatcher
    private let inAppMessageResolver: InAppMessageResolver

    init(
        userOverrideMatcher: InAppMessageMatcher,
        hiddenMatcher: InAppMessageMatcher,
        targetMatcher: InAppMessageMatcher,
        inAppMessageResolver: InAppMessageResolver
    ) {
        self.userOverrideMatcher = userOverrideMatcher
        self.hiddenMatcher = hiddenMatcher
        self.targetMatcher = targetMatcher
        self.inAppMessageResolver = inAppMessageResolver
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {

        // UserOverride
        if try userOverrideMatcher.matches(request: request, context: context) {
            return try evaluation(request: request, context: context, reason: DecisionReason.OVERRIDDEN)
        }

        // Status
        if request.inAppMessage.status == .draft {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_DRAFT)
        }
        if request.inAppMessage.status == .pause {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_PAUSED)
        }

        // Period
        guard request.inAppMessage.period.within(date: request.timestamp) else {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD)
        }

        // Hidden
        if try hiddenMatcher.matches(request: request, context: context) {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_HIDDEN)
        }

        // Target
        if try targetMatcher.matches(request: request, context: context) {
            return try evaluation(request: request, context: context, reason: DecisionReason.IN_APP_MESSAGE_TARGET)
        }

        return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
    }

    private func evaluation(request: Request, context: EvaluatorContext, reason: String) throws -> InAppMessageEvaluation {
        let message = try inAppMessageResolver.resolve(request: request, context: context)
        return InAppMessageEvaluation.of(request: request, context: context, reason: reason, message: message)
    }
}
