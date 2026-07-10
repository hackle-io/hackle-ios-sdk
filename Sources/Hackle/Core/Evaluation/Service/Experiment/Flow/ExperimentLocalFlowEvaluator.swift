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

    func of(request: ExperimentLocalEvaluateRequest, reason: String, variation: Variation) -> ExperimentEvaluation {
        let result = ExperimentEvaluateResult.of(reason: reason, variation: variation)
        return ExperimentEvaluation(entity: request.experiment, result: result)
    }

    func ofControl(request: ExperimentLocalEvaluateRequest, reason: String) throws -> ExperimentEvaluation {
        let result = try ExperimentEvaluateResult.ofControl(reason: reason, request: request)
        return ExperimentEvaluation(entity: request.experiment, result: result)
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
            switch request.experimentConfig.type {
            case .abTest:
                return of(request: request, reason: DecisionReason.OVERRIDDEN, variation: overriddenVariation)
            case .featureFlag:
                return of(request: request, reason: DecisionReason.INDIVIDUAL_TARGET_MATCH, variation: overriddenVariation)
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
        if request.experimentConfig.status == .draft {
            return try ofControl(request: request, reason: DecisionReason.EXPERIMENT_DRAFT)
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
        if request.experimentConfig.status == .paused {
            switch request.experimentConfig.type {
            case .abTest:
                return try ofControl(request: request, reason: DecisionReason.EXPERIMENT_PAUSED)
            case .featureFlag:
                return try ofControl(request: request, reason: DecisionReason.FEATURE_FLAG_INACTIVE)
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
        if request.experimentConfig.status == .completed {
            guard let winnerVariation = request.experimentConfig.winnerVariation else {
                throw HackleError.error("winner variation [\(request.experimentConfig.id)]")
            }
            return of(request: request, reason: DecisionReason.EXPERIMENT_COMPLETED, variation: winnerVariation)
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
        guard request.experimentConfig.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(request.experimentConfig.id)]")
        }

        let isUserInExperimentTarget = try experimentTargetDeterminer.isUserInExperimentTarget(request: request, context: context)
        if isUserInExperimentTarget {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ofControl(request: request, reason: DecisionReason.NOT_IN_EXPERIMENT_TARGET)
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
        guard request.experimentConfig.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experimentConfig.id)]")
        }

        guard request.experimentConfig.type == .abTest else {
            throw HackleError.error("Experiment type must be abTest [\(request.experimentConfig.id)]")
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: request.experimentConfig.defaultRule) else {
            return try ofControl(request: request, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        }

        if variation.isDropped {
            return try ofControl(request: request, reason: DecisionReason.VARIATION_DROPPED)
        }

        return of(request: request, reason: DecisionReason.TRAFFIC_ALLOCATED, variation: variation)
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
        guard request.experimentConfig.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experimentConfig.id)]")
        }

        guard request.experimentConfig.type == .featureFlag else {
            throw HackleError.error("Experiment type must be featureFlag [\(request.experimentConfig.id)]")
        }

        if request.user.identifiers[request.experimentConfig.identifierType] == nil {
            return try nextFlow.evaluate(request: request, context: context)
        }

        guard let targetRule = try targetRuleDeterminer.determineTargetRuleOrNil(request: request, context: context) else {
            return try nextFlow.evaluate(request: request, context: context)
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: targetRule.action) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(request.experimentConfig.id)]")
        }

        return of(request: request, reason: DecisionReason.TARGET_RULE_MATCH, variation: variation)
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
        guard request.experimentConfig.status == .running else {
            throw HackleError.error("Experiment status must be running [\(request.experimentConfig.id)]")
        }

        guard request.experimentConfig.type == .featureFlag else {
            throw HackleError.error("Experiment type must be featureFlag [\(request.experimentConfig.id)]")
        }

        if request.user.identifiers[request.experimentConfig.identifierType] == nil {
            return try ofControl(request: request, reason: DecisionReason.DEFAULT_RULE)
        }

        guard let variation = try actionResolver.resolveOrNil(request: request, action: request.experimentConfig.defaultRule) else {
            throw HackleError.error("FeatureFlag must decide the Variation [\(request.experimentConfig.id)]")
        }

        return of(request: request, reason: DecisionReason.DEFAULT_RULE, variation: variation)
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
        guard let containerId = request.experimentConfig.containerId else {
            return try nextFlow.evaluate(request: request, context: context)
        }

        guard let container = request.workspaceConfig.getContainerOrNil(containerId: containerId) else {
            throw HackleError.error("Container[\(containerId)]")
        }

        let isUserInContainerGroup = try containerResolver.isUserInContainerGroup(request: request, container: container)
        if isUserInContainerGroup {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ofControl(request: request, reason: DecisionReason.NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT)
        }
    }
}

class IdentifierExperimentLocalFlowEvaluator: ExperimentLocalFlowEvaluator {
    func evaluate(
        request: ExperimentLocalEvaluateRequest,
        context: EvaluatorContext,
        nextFlow: ExperimentLocalEvaluationFlow
    ) throws -> ExperimentEvaluation? {
        if request.user.identifiers[request.experimentConfig.identifierType] != nil {
            return try nextFlow.evaluate(request: request, context: context)
        } else {
            return try ofControl(request: request, reason: DecisionReason.IDENTIFIER_NOT_FOUND)
        }
    }
}
