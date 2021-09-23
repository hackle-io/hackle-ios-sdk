import Foundation

protocol FlowEvaluator {
    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation
}

class OverrideEvaluator: FlowEvaluator {
    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if let overriddenVariation = experiment.getOverriddenVariationOrNil(user: user) {
            switch experiment.type {
            case .abTest:
                return Evaluation.of(variation: overriddenVariation, reason: DecisionReason.OVERRIDDEN)
            case .featureFlag:
                return Evaluation.of(variation: overriddenVariation, reason: DecisionReason.INDIVIDUAL_TARGET_MATCH)
            }
        } else {
            return try nextFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        }
    }
}

class DraftExperimentEvaluator: FlowEvaluator {
    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if experiment is DraftExperiment {
            return Evaluation.of(experiment: experiment, variationKey: defaultVariationKey, reason: DecisionReason.EXPERIMENT_DRAFT)
        } else {
            return try nextFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        }
    }
}

class PausedExperimentEvaluator: FlowEvaluator {
    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if experiment is PausedExperiment {
            switch experiment.type {
            case .abTest:
                return Evaluation.of(experiment: experiment, variationKey: defaultVariationKey, reason: DecisionReason.EXPERIMENT_PAUSED)
            case .featureFlag:
                return Evaluation.of(experiment: experiment, variationKey: defaultVariationKey, reason: DecisionReason.FEATURE_FLAG_INACTIVE)
            }
        } else {
            return try nextFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        }
    }
}

class CompletedExperimentEvaluator: FlowEvaluator {
    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if let completedExperiment = experiment as? CompletedExperiment {
            return Evaluation.of(variation: completedExperiment.winnerVariation, reason: DecisionReason.EXPERIMENT_COMPLETED)
        } else {
            return try nextFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        }
    }
}

class ExperimentTargetEvaluator: FlowEvaluator {
    private let experimentTargetDeterminer: ExperimentTargetDeterminer

    init(experimentTargetDeterminer: ExperimentTargetDeterminer) {
        self.experimentTargetDeterminer = experimentTargetDeterminer
    }

    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard let runningExperiment = experiment as? RunningExperiment, runningExperiment.type == .abTest else {
            throw HackleError.error("experiment must be running and abTest type [\(experiment.id)]")
        }

        let isUserInExperimentTarget = experimentTargetDeterminer.isUserInExperimentTarget(workspace: workspace, experiment: runningExperiment, user: user)
        if isUserInExperimentTarget {
            return try nextFlow.evaluate(workspace: workspace, experiment: runningExperiment, user: user, defaultVariationKey: defaultVariationKey)
        } else {
            return Evaluation.of(experiment: runningExperiment, variationKey: defaultVariationKey, reason: DecisionReason.NOT_IN_EXPERIMENT_TARGET)
        }
    }
}

class TrafficAllocateEvaluator: FlowEvaluator {

    private let actionResolver: ActionResolver

    init(actionResolver: ActionResolver) {
        self.actionResolver = actionResolver
    }

    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard let runningExperiment = experiment as? RunningExperiment, runningExperiment.type == .abTest else {
            throw HackleError.error("experiment must be running and abTest type [\(experiment.id)]")
        }

        guard let variation = try actionResolver.resolveOrNil(action: runningExperiment.defaultRule, workspace: workspace, experiment: runningExperiment, user: user) else {
            return Evaluation.of(experiment: runningExperiment, variationKey: defaultVariationKey, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        }

        if variation.isDropped {
            return Evaluation.of(experiment: runningExperiment, variationKey: defaultVariationKey, reason: DecisionReason.VARIATION_DROPPED)
        }

        return Evaluation.of(variation: variation, reason: DecisionReason.TRAFFIC_ALLOCATED)
    }
}

class TargetRuleEvaluator: FlowEvaluator {
    private let targetRuleDeterminer: TargetRuleDeterminer
    private let actionResolver: ActionResolver

    init(targetRuleDeterminer: TargetRuleDeterminer, actionResolver: ActionResolver) {
        self.targetRuleDeterminer = targetRuleDeterminer
        self.actionResolver = actionResolver
    }

    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard let runningExperiment = experiment as? RunningExperiment, runningExperiment.type == .featureFlag else {
            throw HackleError.error("experiment must be running and featureFlag type [\(experiment.id)]")
        }

        guard let targetRule = targetRuleDeterminer.determineTargetRuleOrNil(workspace: workspace, experiment: runningExperiment, user: user) else {
            return try nextFlow.evaluate(workspace: workspace, experiment: runningExperiment, user: user, defaultVariationKey: defaultVariationKey)
        }

        guard let variation = try actionResolver.resolveOrNil(action: targetRule.action, workspace: workspace, experiment: runningExperiment, user: user) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(experiment.id)]")
        }

        return Evaluation.of(variation: variation, reason: DecisionReason.TARGET_RULE_MATCH)
    }
}

class DefaultRuleEvaluator: FlowEvaluator {
    private let actionResolver: ActionResolver

    init(actionResolver: ActionResolver) {
        self.actionResolver = actionResolver
    }

    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: User,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard let runningExperiment = experiment as? RunningExperiment, runningExperiment.type == .featureFlag else {
            throw HackleError.error("experiment must be running and featureFlag type [\(experiment.id)]")
        }

        guard let variation = try actionResolver.resolveOrNil(action: runningExperiment.defaultRule, workspace: workspace, experiment: runningExperiment, user: user) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(runningExperiment.id)]")
        }

        return Evaluation.of(variation: variation, reason: DecisionReason.DEFAULT_RULE)
    }
}
