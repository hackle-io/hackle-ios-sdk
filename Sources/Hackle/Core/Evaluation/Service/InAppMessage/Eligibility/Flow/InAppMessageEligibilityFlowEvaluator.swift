import Foundation

protocol InAppMessageEligibilityFlowEvaluator: FlowEvaluator {
}

/// Period Check
///
/// IAM의 기간에 포함되지 않는 경우 NOT_IN_IN_APP_MESSAGE_PERIOD
class PeriodInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let iamRequest = request as? InAppMessageEligibilityEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityEvaluateRequest)")
        }
        guard iamRequest.inAppMessage.period.within(date: iamRequest.timestamp) else {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD)
            return try evaluation(entity: iamRequest.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

/// Timetable Check
///
/// IAM의 시간표에 포함되지 않는 경우 NOT_IN_IN_APP_MESSAGE_TIMETABLE
class TimetableInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let iamRequest = request as? InAppMessageEligibilityEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityEvaluateRequest)")
        }
        guard iamRequest.inAppMessage.timetable.within(date: iamRequest.timestamp) else {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TIMETABLE)
            return try evaluation(entity: iamRequest.inAppMessage, result: result)
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

    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let iamRequest = request as? InAppMessageEligibilityEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityEvaluateRequest)")
        }
        if try frequencyCapMatcher.matches(request: iamRequest, context: context) {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED)
            return try evaluation(entity: iamRequest.inAppMessage, result: result)
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

    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let iamRequest = request as? InAppMessageEligibilityEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityEvaluateRequest)")
        }
        if try hiddenMatcher.matches(request: iamRequest, context: context) {
            let result = InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.IN_APP_MESSAGE_HIDDEN)
            return try evaluation(entity: iamRequest.inAppMessage, result: result)
        }
        return try nextFlow.evaluate(request: request, context: context)
    }
}

class EligibleInAppMessageEligibilityFlowEvaluator: InAppMessageEligibilityFlowEvaluator {
    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let iamRequest = request as? InAppMessageEligibilityEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: InAppMessageEligibilityEvaluateRequest)")
        }
        let result = InAppMessageEligibilityEvaluateResult.eligible(reason: DecisionReason.IN_APP_MESSAGE_TARGET)
        return try evaluation(entity: iamRequest.inAppMessage, result: result)
    }
}

extension InAppMessageEligibilityFlowEvaluator {
    /// 공유 evaluator가 생성한 evaluation을 flow의 E 타입으로 안전 변환 (기존 브리지 관례)
    func evaluation<E: Evaluation>(entity: InAppMessage, result: InAppMessageEligibilityEvaluateResult) throws -> E {
        let evaluation = InAppMessageEligibilityEvaluation(entity: entity, result: result)
        guard let e = evaluation as? E else {
            throw HackleError.error("Unsupported evaluation: \(type(of: evaluation)) (expected: \(E.self))")
        }
        return e
    }
}
