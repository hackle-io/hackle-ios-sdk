import Foundation

typealias ExperimentLocalEvaluationFlow = EvaluationFlow<ExperimentLocalEvaluateRequest, ExperimentEvaluation>

protocol ExperimentLocalFlowEvaluator: FlowEvaluator {
    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation?
}

extension ExperimentLocalFlowEvaluator {

    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        guard let experimentRequest = request as? ExperimentLocalEvaluateRequest else {
            throw HackleError.error("Unsupported request: \(type(of: request)) (expected: ExperimentLocalEvaluateRequest)")
        }

        guard let experimentNextFlow = nextFlow as? ExperimentLocalEvaluationFlow else {
            throw HackleError.error("Unsupported flow: \(type(of: nextFlow)) (expected: ExperimentLocalEvaluationFlow)")
        }

        let experimentEvaluation = try evaluate(request: experimentRequest, context: context, nextFlow: experimentNextFlow)

        if experimentEvaluation == nil {
            return nil
        }

        guard let evaluation = experimentEvaluation as? E else {
            throw HackleError.error("Unsupported evaluation: \(type(of: experimentEvaluation)) (expected: \(E.self))")
        }

        return evaluation
    }

    func of(request: ExperimentLocalEvaluateRequest, reason: String, variation: Variation) throws -> ExperimentEvaluation {
        let config = try Self.config(workspace: request.workspace, variation: variation)
        let result = ExperimentEvaluateResult.of(reason: reason, variation: variation, config: config)
        return ExperimentEvaluation(entity: request.experiment, result: result)
    }

    func ofDefault(request: ExperimentLocalEvaluateRequest, reason: String) throws -> ExperimentEvaluation {
        let result = try ExperimentEvaluateResult.ofDefault(reason: reason, request: request)
        return ExperimentEvaluation(entity: request.experiment, result: result)
    }

    private static func config(workspace: Workspace, variation: Variation) throws -> ParameterConfiguration? {
        guard let parameterConfigurationId = variation.parameterConfigurationId else {
            return nil
        }

        guard let parameterConfiguration = workspace.getParameterConfigurationOrNil(parameterConfigurationId: parameterConfigurationId) else {
            throw HackleError.error("ParameterConfiguration[\(parameterConfigurationId)]")
        }

        return parameterConfiguration
    }
}

class OverrideExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {

    private let overrideResolver: OverrideResolver

    init(overrideResolver: OverrideResolver) {
        self.overrideResolver = overrideResolver
    }

    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        if let overriddenVariation = try overrideResolver.resolveOrNil(request: request, context: context) {
            switch request.experiment.type {
            case .abTest:
                return try of(request: request, reason: DecisionReason.OVERRIDDEN, variation: overriddenVariation)
            case .featureFlag:
                return try of(request: request, reason: DecisionReason.INDIVIDUAL_TARGET_MATCH, variation: overriddenVariation)
            }
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class DraftExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        if request.experiment.status == .draft {
            return try ofDefault(request: request, reason: DecisionReason.EXPERIMENT_DRAFT)
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class PausedExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        if request.experiment.status == .paused {
            switch request.experiment.type {
            case .abTest:
                return try ofDefault(request: request, reason: DecisionReason.EXPERIMENT_PAUSED)
            case .featureFlag:
                return try ofDefault(request: request, reason: DecisionReason.FEATURE_FLAG_INACTIVE)
            }
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class CompletedExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        if request.experiment.status == .completed {
            guard let winnerVariation = request.experiment.winnerVariation else {
                throw HackleError.error("winner variation [\(request.experiment.id)]")
            }
            return try of(request: request, reason: DecisionReason.EXPERIMENT_COMPLETED, variation: winnerVariation)
        } else {
            return try nextFlow.evaluate(request: request, context: context)
        }
    }
}

class TargetExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    private let experimentTargetDeterminer: ExperimentTargetDeterminer

    init(experimentTargetDeterminer: ExperimentTargetDeterminer) {
        self.experimentTargetDeterminer = experimentTargetDeterminer
    }

    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        guard request.experiment.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(request.experiment.id)]")
        }

        let isUserInExperimentTarget = try experimentTargetDeterminer.isUserInExperimentTarget(request: request, context: context)
        if isUserInExperimentTarget {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ofDefault(request: request, reason: DecisionReason.NOT_IN_EXPERIMENT_TARGET)
        }
    }
}

class TrafficAllocateExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {

    private let actionResolver: ActionResolver

    init(actionResolver: ActionResolver) {
        self.actionResolver = actionResolver
    }

    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        guard request.experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experiment.id)]")
        }

        guard request.experiment.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(request.experiment.id)]")
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: request.experiment.defaultRule) else {
            return try ofDefault(request: request, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        }

        if variation.isDropped {
            return try ofDefault(request: request, reason: DecisionReason.VARIATION_DROPPED)
        }

        return try of(request: request, reason: DecisionReason.TRAFFIC_ALLOCATED, variation: variation)
    }
}

class TargetRuleExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    private let targetRuleDeterminer: ExperimentTargetRuleDeterminer
    private let actionResolver: ActionResolver

    init(targetRuleDeterminer: ExperimentTargetRuleDeterminer, actionResolver: ActionResolver) {
        self.targetRuleDeterminer = targetRuleDeterminer
        self.actionResolver = actionResolver
    }

    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
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

        return try of(request: request, reason: DecisionReason.TARGET_RULE_MATCH, variation: variation)
    }
}

class DefaultRuleExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    private let actionResolver: ActionResolver

    init(actionResolver: ActionResolver) {
        self.actionResolver = actionResolver
    }

    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        guard request.experiment.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experiment.id)]")
        }

        guard request.experiment.type == .featureFlag else {
            throw HackleError.error("Experiment type must be featureFlag [\(request.experiment.id)]")
        }

        if request.user.identifiers[request.experiment.identifierType] == nil {
            return try ofDefault(request: request, reason: DecisionReason.DEFAULT_RULE)
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: request.experiment.defaultRule) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(request.experiment.id)]")
        }

        return try of(request: request, reason: DecisionReason.DEFAULT_RULE, variation: variation)
    }
}

class ContainerExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {

    private let containerResolver: ContainerResolver

    init(containerResolver: ContainerResolver) {
        self.containerResolver = containerResolver
    }

    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
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
            return try ofDefault(request: request, reason: DecisionReason.NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT)
        }
    }
}

class IdentifierExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        if request.user.identifiers[request.experiment.identifierType] != nil {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ofDefault(request: request, reason: DecisionReason.IDENTIFIER_NOT_FOUND)
        }
    }
}
