import Foundation

final class InAppMessageLayoutLocalEvaluator: InAppMessageLayoutEvaluator {
    typealias Request = InAppMessageLayoutLocalEvaluateRequest
    typealias Response = InAppMessageLayoutEvaluateResponse

    private let experimentEvaluator: InAppMessageLayoutExperimentEvaluator
    private let selector: InAppMessageLayoutSelector
    let eventRecorder: EvaluationEventRecorder

    init(
        experimentEvaluator: InAppMessageLayoutExperimentEvaluator,
        selector: InAppMessageLayoutSelector,
        eventRecorder: EvaluationEventRecorder
    ) {
        self.experimentEvaluator = experimentEvaluator
        self.selector = selector
        self.eventRecorder = eventRecorder
    }

    func doEvaluate(request: InAppMessageLayoutLocalEvaluateRequest, context: EvaluatorContext) throws -> InAppMessageLayoutEvaluateResponse {
        let message: InAppMessage.Message
        if let experimentContext = request.inAppMessage.messageContext.experimentContext {
            message = try evaluateExperiment(request: request, context: context, experimentContext: experimentContext)
        } else {
            message = try evaluateDefault(request: request)
        }
        let result = InAppMessageLayoutEvaluateResult.of(reason: DecisionReason.IN_APP_MESSAGE_TARGET, message: message)
        return InAppMessageLayoutEvaluateResponse.of(request: request, context: context, result: result)
    }

    private func evaluateDefault(request: InAppMessageLayoutLocalEvaluateRequest) throws -> InAppMessage.Message {
        let langCondition = langCondition(lang: request.inAppMessage.messageContext.defaultLang)
        return try selector.select(inAppMessage: request.inAppMessage, condition: langCondition)
    }

    private func evaluateExperiment(
        request: InAppMessageLayoutLocalEvaluateRequest,
        context: EvaluatorContext,
        experimentContext: InAppMessage.ExperimentContext
    ) throws -> InAppMessage.Message {
        guard let experiment = request.workspace.getExperimentOrNil(experimentKey: experimentContext.key) as? ExperimentConfig else {
            throw HackleError.error("Experiment[key=\(experimentContext.key)]")
        }
        let experimentEvaluation = try experimentEvaluator.evaluate(sourceRequest: request, context: context, reference: experiment)

        let langCondition = langCondition(lang: request.inAppMessage.messageContext.defaultLang)
        let experimentCondition = experimentCondition(variationKey: experimentEvaluation.experimentResult.variationKey)
        return try selector.select(inAppMessage: request.inAppMessage) { message in
            langCondition(message) && experimentCondition(message)
        }
    }
}

extension InAppMessageLayoutLocalEvaluator {

    private func langCondition(lang: String) -> (InAppMessage.Message) -> Bool {
        return { message in
            lang == message.lang
        }
    }

    private func experimentCondition(variationKey: String) -> (InAppMessage.Message) -> Bool {
        return { message in
            variationKey == message.variationKey
        }
    }
}
