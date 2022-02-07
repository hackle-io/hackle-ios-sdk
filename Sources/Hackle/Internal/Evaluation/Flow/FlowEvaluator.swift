import Foundation

protocol FlowEvaluator {
    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation
}

class OverrideEvaluator: FlowEvaluator {

    private let overrideResolver: OverrideResolver

    init(overrideResolver: OverrideResolver) {
        self.overrideResolver = overrideResolver
    }

    func evaluate(
        workspace: Workspace,
        experiment: Experiment,
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if let overriddenVariation = try overrideResolver.resolveOrNil(workspace: workspace, experiment: experiment, user: user) {
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
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if experiment.status == .draft {
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
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if experiment.status == .paused {
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
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        if experiment.status == .completed {
            guard let winnerVariation = experiment.winnerVariation else {
                throw HackleError.error("winner variation [\(experiment.id)]")
            }
            return Evaluation.of(variation: winnerVariation, reason: DecisionReason.EXPERIMENT_COMPLETED)
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
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard experiment.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(experiment.id)]")
        }

        let isUserInExperimentTarget = try experimentTargetDeterminer.isUserInExperimentTarget(workspace: workspace, experiment: experiment, user: user)
        if isUserInExperimentTarget {
            return try nextFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        } else {
            return Evaluation.of(experiment: experiment, variationKey: defaultVariationKey, reason: DecisionReason.NOT_IN_EXPERIMENT_TARGET)
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
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(experiment.id)]")
        }

        guard experiment.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(experiment.id)]")
        }

        guard let variation = try actionResolver.resolveOrNil(action: experiment.defaultRule, workspace: workspace, experiment: experiment, user: user) else {
            return Evaluation.of(experiment: experiment, variationKey: defaultVariationKey, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        }

        if variation.isDropped {
            return Evaluation.of(experiment: experiment, variationKey: defaultVariationKey, reason: DecisionReason.VARIATION_DROPPED)
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
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(experiment.id)]")
        }

        guard experiment.type == .featureFlag else {
            throw HackleError.error("Experiment type must be featureFlag [\(experiment.id)]")
        }

        guard let targetRule = try targetRuleDeterminer.determineTargetRuleOrNil(workspace: workspace, experiment: experiment, user: user) else {
            return try nextFlow.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: defaultVariationKey)
        }

        guard let variation = try actionResolver.resolveOrNil(action: targetRule.action, workspace: workspace, experiment: experiment, user: user) else {
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
        user: HackleUser,
        defaultVariationKey: Variation.Key,
        nextFlow: EvaluationFlow
    ) throws -> Evaluation {
        guard experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(experiment.id)]")
        }

        guard experiment.type == .featureFlag else {
            throw HackleError.error("Experiment type must be featureFlag [\(experiment.id)]")
        }

        guard let variation = try actionResolver.resolveOrNil(action: experiment.defaultRule, workspace: workspace, experiment: experiment, user: user) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(experiment.id)]")
        }

        return Evaluation.of(variation: variation, reason: DecisionReason.DEFAULT_RULE)
    }
}
