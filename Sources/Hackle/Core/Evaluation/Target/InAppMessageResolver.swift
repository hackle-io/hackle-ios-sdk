//
//  InAppMessageResolver.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation

protocol InAppMessageResolver {
    func resolve(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message
}

class DefaultInAppMessageResolver: InAppMessageResolver {

    private let experimentEvaluator: InAppMessageExperimentEvaluator
    private let messageSelector: InAppMessageSelector

    init(experimentEvaluator: InAppMessageExperimentEvaluator, messageSelector: InAppMessageSelector) {
        self.experimentEvaluator = experimentEvaluator
        self.messageSelector = messageSelector
    }

    func resolve(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message {
        guard let experiment = try experiment(request: request) else {
            return try messageSelector.select(request: request) { message in
                return message.lang == request.inAppMessage.messageContext.defaultLang
            }
        }
        
        let evaluation = try experimentEvaluator.evaluate(request: request, context: context, experiment: experiment)
        return try messageSelector.select(request: request) { message in
            return message.lang == request.inAppMessage.messageContext.defaultLang && evaluation.variationKey == message.variationKey
        }
    }

    private func experiment(request: InAppMessageRequest) throws -> Experiment? {
        guard let experimentContext = request.inAppMessage.messageContext.experimentContext else {
            return nil
        }
        
        guard let experiment = request.workspace.getExperimentOrNil(experimentKey: experimentContext.key) else {
            throw HackleError.error("Experiment[\(experimentContext.key)]")
        }
        
        return experiment
    }
}

class InAppMessageExperimentEvaluator: ExperimentContextualEvaluator {

    let evaluator: Evaluator
    
    init(evaluator: Evaluator) {
        self.evaluator = evaluator
    }
    
    func decorate(request: EvaluatorRequest, context: EvaluatorContext, evaluation: EvaluatorEvaluation) throws -> ExperimentEvaluation {
        guard let experimentEvaluation = evaluation as? ExperimentEvaluation else {
            throw HackleError.error("Unsupported evaluation: \(type(of: evaluation)) (expected: \(ExperimentEvaluation.self))")
        }
        
        context.setProperty("experiment_id", experimentEvaluation.experiment.id)
        context.setProperty("experiment_key", experimentEvaluation.experiment.key)
        context.setProperty("variation_id", experimentEvaluation.variationId)
        context.setProperty("variation_key", experimentEvaluation.variationKey)
        context.setProperty("experiment_decision_reason", experimentEvaluation.reason)
        
        return experimentEvaluation
    }
}

class InAppMessageSelector {
    func select(request: InAppMessageRequest, condition: (InAppMessage.Message) -> Bool) throws -> InAppMessage.Message {
        guard let message = request.inAppMessage.messageContext.messages.first(where: condition) else {
            throw HackleError.error("InAppMessage must be decided [\(request.inAppMessage.key)]")
        }
        
        return message
    }
}
