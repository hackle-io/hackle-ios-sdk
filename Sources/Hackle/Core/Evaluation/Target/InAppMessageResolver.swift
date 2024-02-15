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

    private let evaluator: Evaluator

    init(evaluator: Evaluator) {
        self.evaluator = evaluator
    }

    func resolve(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message {
        if let message = try resolveExperiment(request: request, context: context) {
            return message
        } else {
            return try resolveDefault(request: request, context: context)
        }
    }

    private func resolveExperiment(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message? {
        guard let experimentContext = request.inAppMessage.messageContext.experimentContext else {
            return nil
        }

        guard let experiment = request.workspace.getExperimentOrNil(experimentKey: experimentContext.key) else {
            throw HackleError.error("Experiment[\(experimentContext.key)]")
        }

        let experimentRequest = ExperimentRequest.of(requestedBy: request, experiment: experiment)
        let experimentEvaluation: ExperimentEvaluation = try evaluator.evaluate(request: experimentRequest, context: context)
        addExperimentContext(evaluation: experimentEvaluation, context: context)

        let lang = request.inAppMessage.messageContext.defaultLang
        return try resolveMessage(request: request) { it in
            it.lang == lang && experimentEvaluation.variationKey == it.variationKey
        }
    }

    private func addExperimentContext(evaluation: ExperimentEvaluation, context: EvaluatorContext) {
        context.add(evaluation)
        context.setProperty("experiment_id", evaluation.experiment.id)
        context.setProperty("experiment_key", evaluation.experiment.key)
        context.setProperty("variation_id", evaluation.variationId)
        context.setProperty("variation_key", evaluation.variationKey)
        context.setProperty("experiment_decision_reason", evaluation.reason)
    }

    private func resolveDefault(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message {
        let lang = request.inAppMessage.messageContext.defaultLang
        return try resolveMessage(request: request) { it in
            it.lang == lang
        }
    }

    private func resolveMessage(request: InAppMessageRequest, predicate: (InAppMessage.Message) -> Bool) throws -> InAppMessage.Message {
        guard let message = request.inAppMessage.messageContext.messages.first(where: predicate) else {
            throw HackleError.error("InAppMessage must be decided [\(request.inAppMessage.key)]")
        }
        return message
    }
}

protocol InAppMessageMatcher {
    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool
}

class InAppMessageUserOverrideMatcher: InAppMessageMatcher {
    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        let userOverrides = request.inAppMessage.targetContext.overrides
        if userOverrides.isEmpty {
            return false
        }
        return userOverrides.contains { it in
            isUserOverridden(request: request, userOverride: it)
        }
    }

    private func isUserOverridden(request: InAppMessageRequest, userOverride: InAppMessage.UserOverride) -> Bool {
        guard let identifier = request.user.identifiers[userOverride.identifierType] else {
            return false
        }
        return userOverride.identifiers.contains(identifier)
    }
}

class InAppMessageTargetMatcher: InAppMessageMatcher {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        let targets = request.inAppMessage.targetContext.targets
        if targets.isEmpty {
            return true
        }

        return try targets.contains { it in
            try targetMatcher.matches(request: request, context: context, target: it)
        }
    }
}


class InAppMessageHiddenMatcher: InAppMessageMatcher {

    private let storage: InAppMessageHiddenStorage

    init(storage: InAppMessageHiddenStorage) {
        self.storage = storage
    }

    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        storage.exist(inAppMessage: request.inAppMessage, now: request.timestamp)
    }
}
