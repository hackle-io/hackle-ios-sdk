import Foundation

protocol InAppMessageEligibilityFlowEvaluator: FlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation?
}

extension InAppMessageEligibilityFlowEvaluator {
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

/// Period Check
///
/// IAM의 기간에 포함되지 않는 경우 NOT_IN_IN_APP_MESSAGE_PERIOD
class PeriodInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        guard request.inAppMessage.period.within(date: request.timestamp) else {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Timetable Check
///
/// IAM의 시간표에 포함되지 않는 경우 NOT_IN_IN_APP_MESSAGE_TIMETABLE
class TimetableInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        guard request.inAppMessage.timetable.within(date: request.timestamp) else {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TIMETABLE)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// 노출 빈도수 체크
class FrequencyCapInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    private let frequencyCapMatcher: InAppMessageMatcher

    init(frequencyCapMatcher: InAppMessageMatcher) {
        self.frequencyCapMatcher = frequencyCapMatcher
    }

    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if try frequencyCapMatcher.matches(request: request, context: context) {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Hidden Check
///
/// SDK 에서 판단해서 숨겨야 하는 경우
/// - 하루동안 가리기 설정된 경우
class HiddenInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    private let hiddenMatcher: InAppMessageMatcher

    init(hiddenMatcher: InAppMessageMatcher) {
        self.hiddenMatcher = hiddenMatcher
    }

    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        if try hiddenMatcher.matches(request: request, context: context) {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.IN_APP_MESSAGE_HIDDEN)
            return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class EligibleInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate(
        request: InAppMessageEligibilityLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: InAppMessageEligibilityLocalEvaluationFlow
    ) throws -> InAppMessageEligibilityEvaluation? {
        let result = InAppMessageEligibilityEvaluateResult.eligible(reason: DecisionReason.IN_APP_MESSAGE_TARGET)
        return InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result)
    }
}
