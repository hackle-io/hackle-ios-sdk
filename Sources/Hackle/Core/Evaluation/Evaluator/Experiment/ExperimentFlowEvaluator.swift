import Foundation

typealias ExperimentFlow = EvaluationFlow<ExperimentRequest, ExperimentEvaluation>

protocol ExperimentFlowEvaluator: FlowEvaluator {
    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation?
}

extension ExperimentFlowEvaluator {
    func evaluate<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, Evaluation>
    ) throws -> Evaluation? {
        guard let experimentRequest = request as? ExperimentRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: ExperimentRequest)")
        }

        guard let experimentNextFlow = nextFlow as? ExperimentFlow else {
            throw HackleError.error("Unsupported flow: \(type(of: nextFlow)) (expected: ExperimentFlow)")
        }

        let experimentEvaluation = try evaluateExperiment(request: experimentRequest, context: context, nextFlow: experimentNextFlow)

        if experimentEvaluation == nil {
            return nil
        }

        guard let evaluation = experimentEvaluation as? Evaluation else {
            throw HackleError.error("Unsupported evaluation: \(type(of: experimentEvaluation)) (expected: \(Evaluation.self))")
        }

        return evaluation
    }
}

class OverrideEvaluator: ExperimentFlowEvaluator {

    private let overrideResolver: OverrideResolver

    init(overrideResolver: OverrideResolver) {
        self.overrideResolver = overrideResolver
    }

    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        if let overriddenVariation = try overrideResolver.resolveOrNil(request: request, context: context) {
            switch request.experiment.type {
            case .abTest:
                return try ExperimentEvaluation.of(request: request, context: context, variation: overriddenVariation, reason: DecisionReason.OVERRIDDEN)
            case .featureFlag:
                return try ExperimentEvaluation.of(request: request, context: context, variation: overriddenVariation, reason: DecisionReason.INDIVIDUAL_TARGET_MATCH)
            }
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class DraftExperimentEvaluator: ExperimentFlowEvaluator {
    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        if request.experiment.status == .draft {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.EXPERIMENT_DRAFT)
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class PausedExperimentEvaluator: ExperimentFlowEvaluator {
    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        if request.experiment.status == .paused {
            switch request.experiment.type {
            case .abTest:
                return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.EXPERIMENT_PAUSED)
            case .featureFlag:
                return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.FEATURE_FLAG_INACTIVE)
            }
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class CompletedExperimentEvaluator: ExperimentFlowEvaluator {
    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        if request.experiment.status == .completed {
            guard let winnerVariation = request.experiment.winnerVariation else {
                throw HackleError.error("winner variation [\(request.experiment.id)]")
            }
            return try ExperimentEvaluation.of(request: request, context: context, variation: winnerVariation, reason: DecisionReason.EXPERIMENT_COMPLETED)
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class ExperimentTargetEvaluator: ExperimentFlowEvaluator {
    private let experimentTargetDeterminer: ExperimentTargetDeterminer

    init(experimentTargetDeterminer: ExperimentTargetDeterminer) {
        self.experimentTargetDeterminer = experimentTargetDeterminer
    }

    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        guard request.experiment.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(request.experiment.id)]")
        }

        let isUserInExperimentTarget = try experimentTargetDeterminer.isUserInExperimentTarget(request: request, context: context)
        if isUserInExperimentTarget {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.NOT_IN_EXPERIMENT_TARGET)
        }
    }
}

class TrafficAllocateEvaluator: ExperimentFlowEvaluator {

    private let actionResolver: ActionResolver

    init(actionResolver: ActionResolver) {
        self.actionResolver = actionResolver
    }

    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        guard request.experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experiment.id)]")
        }

        guard request.experiment.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(request.experiment.id)]")
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: request.experiment.defaultRule) else {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        }

        if variation.isDropped {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.VARIATION_DROPPED)
        }

        return try ExperimentEvaluation.of(request: request, context: context, variation: variation, reason: DecisionReason.TRAFFIC_ALLOCATED)
    }
}

class TargetRuleEvaluator: ExperimentFlowEvaluator {
    private let targetRuleDeterminer: ExperimentTargetRuleDeterminer
    private let actionResolver: ActionResolver

    init(targetRuleDeterminer: ExperimentTargetRuleDeterminer, actionResolver: ActionResolver) {
        self.targetRuleDeterminer = targetRuleDeterminer
        self.actionResolver = actionResolver
    }

    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        guard request.experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experiment.id)]")
        }

        guard request.experiment.type == .featureFlag else {
            throw HackleError.error("Experiment type must be featureFlag [\(request.experiment.id)]")
        }

        if request.user.identifiers[request.experiment.identifierType] == nil {
            return try nextFlow.evaluate(request: request, context: context)
        }

        guard let targetRule = try targetRuleDeterminer.determineTargetRuleOrNil(request: request, context: context) else {
            return try nextFlow.evaluate(request: request, context: context)
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: targetRule.action) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(request.experiment.id)]")
        }

        return try ExperimentEvaluation.of(request: request, context: context, variation: variation, reason: DecisionReason.TARGET_RULE_MATCH)
    }
}

class DefaultRuleEvaluator: ExperimentFlowEvaluator {
    private let actionResolver: ActionResolver

    init(actionResolver: ActionResolver) {
        self.actionResolver = actionResolver
    }

    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        guard request.experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experiment.id)]")
        }

        guard request.experiment.type == .featureFlag else {
            throw HackleError.error("Experiment type must be featureFlag [\(request.experiment.id)]")
        }

        if request.user.identifiers[request.experiment.identifierType] == nil {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.DEFAULT_RULE)
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: request.experiment.defaultRule) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(request.experiment.id)]")
        }

        return try ExperimentEvaluation.of(request: request, context: context, variation: variation, reason: DecisionReason.DEFAULT_RULE)
    }
}

class ContainerEvaluator: ExperimentFlowEvaluator {

    private let containerResolver: ContainerResolver

    init(containerResolver: ContainerResolver) {
        self.containerResolver = containerResolver
    }

    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        guard let containerId = request.experiment.containerId else {
            return try nextFlow.evaluate(request: request, context: context)
        }

        guard let container = request.workspace.getContainerOrNil(containerId: containerId) else {
            throw HackleError.error("Container[\(containerId)]")
        }

        let isUserInContainerGroup = try containerResolver.isUserInContainerGroup(request: request, container: container)
        if isUserInContainerGroup {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT)
        }
    }
}

class IdentifierEvaluator: ExperimentFlowEvaluator {
    func evaluateExperiment(
        request: ExperimentRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentFlow
    ) throws -> ExperimentEvaluation? {
        if request.user.identifiers[request.experiment.identifierType] != nil {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.IDENTIFIER_NOT_FOUND)
        }
    }
}
