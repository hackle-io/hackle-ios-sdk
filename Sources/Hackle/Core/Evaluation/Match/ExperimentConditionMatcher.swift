//
//  ExperimentConditionMatcher.swift
//  Hackle
//

import Foundation


class ExperimentConditionMatcher: ConditionMatcher {

    private let abTestMatcher: ExperimentMatcher
    private let featureFlagMatcher: ExperimentMatcher

    init(abTestMatcher: ExperimentMatcher, featureFlagMatcher: ExperimentMatcher) {
        self.abTestMatcher = abTestMatcher
        self.featureFlagMatcher = featureFlagMatcher
    }

    func matches(request: EvaluateRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        guard let request = request as? LocalEvaluateRequest else {
            return false
        }
        switch condition.key.type {
        case .abTest:
            return try abTestMatcher.matches(request: request, context: context, condition: condition)
        case .featureFlag:
            return try featureFlagMatcher.matches(request: request, context: context, condition: condition)
        case .userId, .userProperty, .hackleProperty, .eventProperty, .segment, .cohort, .numberOfEventsInDays, .numberOfEventsWithPropertyInDays:
            throw HackleError.error("Unsupported TargetKeyType [\(condition.key.type)]")
        }
    }
}

protocol ExperimentMatcher {
    func matches(request: LocalEvaluateRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool
}

protocol ExperimentEvaluatorMatcher: ExperimentMatcher, ExperimentReferenceLocalEvaluator {
    var valueOperatorMatcher: ValueOperatorMatcher { get }

    func experiment(request: LocalEvaluateRequest, key: Int64) -> ExperimentConfig?
    func matches(evaluation: ExperimentEvaluation, condition: Target.Condition) -> Bool
}

extension ExperimentEvaluatorMatcher {
    func matches(request: LocalEvaluateRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {

        guard let key = Int64(condition.key.name) else {
            throw HackleError.error("Invalid key [\(condition.key.type.rawValue), \(condition.key.name)]")
        }

        guard let experiment = experiment(request: request, key: key) else {
            return false
        }

        let evaluation = try evaluate(sourceRequest: request, context: context, reference: experiment)
        return matches(evaluation: evaluation, condition: condition)
    }
}

class AbTestConditionMatcher: ExperimentEvaluatorMatcher {

    private static let AB_TEST_MATCHED_REASONS = [
        DecisionReason.OVERRIDDEN,
        DecisionReason.TRAFFIC_ALLOCATED,
        DecisionReason.EXPERIMENT_COMPLETED,
        DecisionReason.TRAFFIC_ALLOCATED_BY_TARGETING
    ]

    internal let evaluator: Evaluator
    internal let valueOperatorMatcher: ValueOperatorMatcher

    init(evaluator: Evaluator, valueOperatorMatcher: ValueOperatorMatcher) {
        self.evaluator = evaluator
        self.valueOperatorMatcher = valueOperatorMatcher
    }

    func experiment(request: LocalEvaluateRequest, key: Int64) -> ExperimentConfig? {
        request.workspace.getExperimentOrNil(experimentKey: key) as? ExperimentConfig
    }

    func resolveEvaluation(sourceRequest: LocalEvaluateRequest, experimentResponse: ExperimentEvaluateResponse) throws -> ExperimentEvaluation {
        let evaluation = experimentResponse.experimentEvaluation
        if sourceRequest is ExperimentEvaluateRequest && evaluation.experimentResult.reason == DecisionReason.TRAFFIC_ALLOCATED {
            return ExperimentEvaluation(entity: evaluation.experiment, result: evaluation.experimentResult.with(reason: DecisionReason.TRAFFIC_ALLOCATED_BY_TARGETING))
        }
        return evaluation
    }

    func matches(evaluation: ExperimentEvaluation, condition: Target.Condition) -> Bool {
        if !AbTestConditionMatcher.AB_TEST_MATCHED_REASONS.contains(evaluation.experimentResult.reason) {
            return false
        }

        return valueOperatorMatcher.matches(userValue: evaluation.experimentResult.variationKey, match: condition.match)
    }
}

class FeatureFlagConditionMatcher: ExperimentEvaluatorMatcher {

    internal let evaluator: Evaluator
    internal let valueOperatorMatcher: ValueOperatorMatcher

    init(evaluator: Evaluator, valueOperatorMatcher: ValueOperatorMatcher) {
        self.evaluator = evaluator
        self.valueOperatorMatcher = valueOperatorMatcher
    }

    func experiment(request: LocalEvaluateRequest, key: Int64) -> ExperimentConfig? {
        request.workspace.getFeatureFlagOrNil(featureKey: key) as? ExperimentConfig
    }

    func resolveEvaluation(sourceRequest: LocalEvaluateRequest, experimentResponse: ExperimentEvaluateResponse) throws -> ExperimentEvaluation {
        experimentResponse.experimentEvaluation
    }

    func matches(evaluation: ExperimentEvaluation, condition: Target.Condition) -> Bool {
        let on = evaluation.experimentResult.variationKey != "A"
        return valueOperatorMatcher.matches(userValue: on, match: condition.match)
    }
}
