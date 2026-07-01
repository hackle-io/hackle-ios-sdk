import Foundation

class EvaluateProcessor {

    private let evaluatorFactory: EvaluatorFactory

    init(evaluatorFactory: EvaluatorFactory) {
        self.evaluatorFactory = evaluatorFactory
    }

    static func create(
        context: EvaluationContext,
        clock: Clock,
        eventProcessor: UserEventProcessor,
        overrideStorage: ManualOverrideStorage,
        impressionStorage: InAppMessageImpressionStorage,
        hiddenStorage: InAppMessageHiddenStorage
    ) -> EvaluateProcessor {
        let evaluatorFactory = EvaluatorFactory()
        let delegatingEvaluator = DelegatingEvaluator(evaluatorFactory: evaluatorFactory)

        let eventFactory = EvaluationEventFactory(clock: clock)
        let eventRecorder = EvaluationEventRecorder(
            eventFactory: eventFactory,
            eventProcessor: eventProcessor
        )

        let targetMatcher = DefaultTargetMatcher(
            conditionMatcherFactory: DefaultConditionMatcherFactory(
                evaluator: delegatingEvaluator,
                clock: clock
            )
        )
        context.register(targetMatcher)

        let bucketer = DefaultBucketer()

        // ===== Local =====

        let experimentLocalEvaluator = ExperimentLocalEvaluator(
            evaluationFlowFactory: DefaultExperimentLocalEvaluationFlowFactory(
                targetMatcher: targetMatcher,
                bucketer: bucketer,
                overrideStorage: overrideStorage
            ),
            eventRecorder: eventRecorder
        )
        let remoteConfigLocalEvaluator = RemoteConfigLocalEvaluator(
            targetRuleDeterminer: RemoteConfigParameterTargetRuleDeterminer(
                matcher: RemoteConfigParameterTargetRuleMatcher(
                    targetMatcher: targetMatcher,
                    bucketer: bucketer
                )
            ),
            eventRecorder: eventRecorder
        )
        let inAppMessageLayoutLocalEvaluator = InAppMessageLayoutLocalEvaluator(
            experimentEvaluator: InAppMessageLayoutExperimentEvaluator(
                evaluator: delegatingEvaluator
            ),
            selector: InAppMessageLayoutSelector(),
            eventRecorder: eventRecorder
        )
        let inAppMessageEligibilityLocalEvaluator = InAppMessageEligibilityLocalEvaluator(
            evaluationFlowFactory: DefaultInAppMessageEligibilityLocalEvaluationFlowFactory(
                targetMatcher: targetMatcher,
                impressionStorage: impressionStorage,
                hiddenStorage: hiddenStorage,
                layoutEvaluator: inAppMessageLayoutLocalEvaluator
            ),
            eventRecorder: eventRecorder
        )

        evaluatorFactory.add(experimentLocalEvaluator)
        evaluatorFactory.add(remoteConfigLocalEvaluator)
        evaluatorFactory.add(inAppMessageLayoutLocalEvaluator)
        evaluatorFactory.add(inAppMessageEligibilityLocalEvaluator)

        return EvaluateProcessor(evaluatorFactory: evaluatorFactory)
    }

    // 타입드 진입점(experiment/remoteConfig/inAppMessage x2)은 step 3/4/5에서 추가.

    fileprivate func evaluate<Res: EvaluateResponse>(evaluator: any Evaluator, request: EvaluateRequest) throws -> Res {
        let response: Res = try evaluator.evaluate(request: request, context: Evaluators.context())
        if request.record {
            evaluator.record(request: request, response: response)
        }
        return response
    }
}

extension EvaluateProcessor {
    func experiment(_ request: ExperimentEvaluateRequest) throws -> ExperimentEvaluateResponse {
        try evaluate(evaluator: try evaluatorFactory.experiment(request), request: request)
    }

    func remoteConfig(_ request: RemoteConfigEvaluateRequest) throws -> RemoteConfigEvaluateResponse {
        try evaluate(evaluator: try evaluatorFactory.remoteConfig(request), request: request)
    }

    func inAppMessage(_ request: InAppMessageEligibilityEvaluateRequest) throws -> InAppMessageEligibilityEvaluateResponse {
        try evaluate(evaluator: try evaluatorFactory.inAppMessage(request), request: request)
    }

    func inAppMessage(_ request: InAppMessageLayoutEvaluateRequest) throws -> InAppMessageLayoutEvaluateResponse {
        try evaluate(evaluator: try evaluatorFactory.inAppMessage(request), request: request)
    }
}
