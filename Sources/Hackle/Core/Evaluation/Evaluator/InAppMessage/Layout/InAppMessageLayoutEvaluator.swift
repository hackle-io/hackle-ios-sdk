import Foundation

class InAppMessageLayoutEvaluator: ContextualEvaluator {
    typealias Request = InAppMessageLayoutRequest
    typealias Evaluation = InAppMessageLayoutEvaluation

    private let experimentEvaluator: InAppMessageExperimentEvaluator
    private let selector: InAppMessageLayoutSelector

    init(experimentEvaluator: InAppMessageExperimentEvaluator, selector: InAppMessageLayoutSelector) {
        self.experimentEvaluator = experimentEvaluator
        self.selector = selector
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
        let message: InAppMessage.Message
        if let experimentContext = request.inAppMessage.messageContext.experimentContext {
            message = try evaluateExperiment(request: request, context: context, experimentContext: experimentContext)
        } else {
            message = try evaluateDefault(request: request, context: context)
        }
        return InAppMessageLayoutEvaluation.of(request: request, context: context, message: message)
    }

    private func evaluateDefault(request: InAppMessageLayoutRequest, context: EvaluatorContext) throws -> InAppMessage.Message {
        let langCondition = langCondition(lang: request.inAppMessage.messageContext.defaultLang)
        return try selector.select(inAppMessage: request.inAppMessage, condition: langCondition)
    }

    private func evaluateExperiment(
        request: InAppMessageLayoutRequest,
        context: EvaluatorContext,
        experimentContext: InAppMessage.ExperimentContext
    ) throws -> InAppMessage.Message {
        guard let experiment = request.workspace.getExperimentOrNil(experimentKey: experimentContext.key) else {
            throw HackleError.error("Experiment[\(experimentContext.key)]")
        }
        let experimentEvaluation = try experimentEvaluator.evaluate(request: request, context: context, experiment: experiment)

        let langCondition = langCondition(lang: request.inAppMessage.messageContext.defaultLang)
        let experimentCondition = experimentCondition(variationKey: experimentEvaluation.variationKey)
        return try selector.select(inAppMessage: request.inAppMessage) { message in
            langCondition(message) && experimentCondition(message)
        }
    }
}

extension InAppMessageLayoutEvaluator {

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
