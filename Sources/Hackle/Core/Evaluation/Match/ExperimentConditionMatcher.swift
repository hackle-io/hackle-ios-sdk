//
//  ExperimentConditionMatcher.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation


class ExperimentConditionMatcher: ConditionMatcher {

    private let abTestMatcher: ExperimentMatcher
    private let featureFlagMatcher: ExperimentMatcher

    init(abTestMatcher: ExperimentMatcher, featureFlagMatcher: ExperimentMatcher) {
        self.abTestMatcher = abTestMatcher
        self.featureFlagMatcher = featureFlagMatcher
    }

    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        switch condition.key.type {
        case .abTest:
            return try abTestMatcher.matches(request: request, context: context, condition: condition)
        case .featureFlag:
            return try featureFlagMatcher.matches(request: request, context: context, condition: condition)
        case .userId, .userProperty, .hackleProperty, .eventProperty, .segment, .cohort, .numberOfEventsInDays:
            throw HackleError.error("Unsupported TargetKeyType [\(condition.key.type)]")
        }
    }
}

protocol ExperimentMatcher {
    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool
}

protocol ExperimentEvaluatorMatcher: ExperimentMatcher {
    var evaluator: Evaluator { get }
    var valueOperatorMatcher: ValueOperatorMatcher { get }

    func experiment(request: EvaluatorRequest, key: Int64) -> Experiment?
    func resolve(request: EvaluatorRequest, evaluation: ExperimentEvaluation) -> ExperimentEvaluation
    func matches(evaluation: ExperimentEvaluation, condition: Target.Condition) -> Bool
}

extension ExperimentEvaluatorMatcher {
    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {

        guard let key = Int64(condition.key.name) else {
            throw HackleError.error("Invalid key [\(condition.key.type.rawValue), \(condition.key.name)]")
        }

        guard let experiment = experiment(request: request, key: key) else {
            return false
        }

        let evaluation = try context.get(experiment) ?? evaluate(request: request, context: context, experiment: experiment)

        return matches(evaluation: evaluation as! ExperimentEvaluation, condition: condition)
    }

    private func evaluate(
        request: EvaluatorRequest,
        context: EvaluatorContext,
        experiment: Experiment
    ) throws -> EvaluatorEvaluation {
        let experimentRequest = ExperimentRequest.of(requestedBy: request, experiment: experiment)
        let evaluation: ExperimentEvaluation = try evaluator.evaluate(request: experimentRequest, context: context)
        let resolvedEvaluation = resolve(request: request, evaluation: evaluation)
        context.add(resolvedEvaluation)
        return resolvedEvaluation
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

    func experiment(request: EvaluatorRequest, key: Int64) -> Experiment? {
        request.workspace.getExperimentOrNil(experimentKey: key)
    }

    func resolve(request: EvaluatorRequest, evaluation: ExperimentEvaluation) -> ExperimentEvaluation {
        if request is ExperimentRequest && evaluation.reason == DecisionReason.TRAFFIC_ALLOCATED {
            return evaluation.with(reason: DecisionReason.TRAFFIC_ALLOCATED_BY_TARGETING)
        }
        return evaluation
    }

    func matches(evaluation: ExperimentEvaluation, condition: Target.Condition) -> Bool {
        if !AbTestConditionMatcher.AB_TEST_MATCHED_REASONS.contains(evaluation.reason) {
            return false
        }

        return valueOperatorMatcher.matches(userValue: evaluation.variationKey, match: condition.match)
    }
}

class FeatureFlagConditionMatcher: ExperimentEvaluatorMatcher {

    internal let evaluator: Evaluator
    internal let valueOperatorMatcher: ValueOperatorMatcher

    init(evaluator: Evaluator, valueOperatorMatcher: ValueOperatorMatcher) {
        self.evaluator = evaluator
        self.valueOperatorMatcher = valueOperatorMatcher
    }

    func experiment(request: EvaluatorRequest, key: Int64) -> Experiment? {
        request.workspace.getFeatureFlagOrNil(featureKey: key)
    }

    func resolve(request: EvaluatorRequest, evaluation: ExperimentEvaluation) -> ExperimentEvaluation {
        evaluation
    }

    func matches(evaluation: ExperimentEvaluation, condition: Target.Condition) -> Bool {
        let on = evaluation.variationKey != "A"
        return valueOperatorMatcher.matches(userValue: on, match: condition.match)
    }
}
