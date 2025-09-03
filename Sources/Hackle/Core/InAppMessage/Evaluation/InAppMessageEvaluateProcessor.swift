import Foundation

protocol InAppMessageEvaluateProcessor {
    func process(type: InAppMessageEvaluateType, request: InAppMessageEligibilityRequest) throws -> InAppMessageEligibilityEvaluation
}

class DefaultInAppMessageEvaluateProcessor: InAppMessageEvaluateProcessor {
    private let core: HackleCore
    private let flowFactory: InAppMessageEligibilityFlowFactory
    private let eventRecorder: EvaluationEventRecorder

    init(core: HackleCore, flowFactory: InAppMessageEligibilityFlowFactory, eventRecorder: EvaluationEventRecorder) {
        self.core = core
        self.flowFactory = flowFactory
        self.eventRecorder = eventRecorder
    }

    func process(
        type: InAppMessageEvaluateType,
        request: InAppMessageEligibilityRequest
    ) throws -> InAppMessageEligibilityEvaluation {
        let flow = resolveFlow(type: type, request: request)
        let evaluator = InAppMessageEligibilityEvaluator(flow: flow, eventRecorder: eventRecorder)
        return try core.inAppMessage(request: request, context: Evaluators.context(), evaluator: evaluator)
    }

    private func resolveFlow(type: InAppMessageEvaluateType, request: InAppMessageEligibilityRequest) -> InAppMessageEligibilityFlow {
        switch type {
        case .trigger:
            return flowFactory.triggerFlow()
        case .deliver:
            return flowFactory.deliverFlow(reEvaluate: request.inAppMessage.evaluateContext.atDeliverTime)
        }
    }
}
