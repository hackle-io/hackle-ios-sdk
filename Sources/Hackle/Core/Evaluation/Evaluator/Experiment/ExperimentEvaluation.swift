//
//  ExperimentEvaluation.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

class ExperimentEvaluation: EvaluatorEvaluation, Equatable {
    let reason: String
    let targetEvaluations: [EvaluatorEvaluation]
    let experiment: Experiment
    let variationId: Variation.Id?
    let variationKey: Variation.Key
    let config: ParameterConfiguration?

    init(reason: String, targetEvaluations: [EvaluatorEvaluation], experiment: Experiment, variationId: Variation.Id?, variationKey: Variation.Key, config: ParameterConfiguration?) {
        self.reason = reason
        self.targetEvaluations = targetEvaluations
        self.experiment = experiment
        self.variationId = variationId
        self.variationKey = variationKey
        self.config = config
    }

    func with(reason: String) -> ExperimentEvaluation {
        ExperimentEvaluation(
            reason: reason,
            targetEvaluations: targetEvaluations,
            experiment: experiment,
            variationId: variationId,
            variationKey: variationKey,
            config: config
        )
    }

    static func ==(lhs: ExperimentEvaluation, rhs: ExperimentEvaluation) -> Bool {
        lhs.experiment.id == rhs.experiment.id && lhs.variationId == rhs.variationId && lhs.variationKey == rhs.variationKey && lhs.reason == rhs.reason && lhs.config?.id == rhs.config?.id
    }

    static func ofDefault(
        request: ExperimentRequest,
        context: EvaluatorContext,
        reason: String
    ) throws -> ExperimentEvaluation {
        guard let variation = request.experiment.getVariationOrNil(variationKey: request.defaultVariationKey) else {
            return ExperimentEvaluation(
                reason: reason,
                targetEvaluations: context.targetEvaluations,
                experiment: request.experiment,
                variationId: nil,
                variationKey: request.defaultVariationKey,
                config: nil
            )
        }
        return try of(request: request, context: context, variation: variation, reason: reason)
    }

    static func of(
        request: ExperimentRequest,
        context: EvaluatorContext,
        variation: Variation,
        reason: String
    ) throws -> ExperimentEvaluation {
        let parameterConfiguration = try config(workspace: request.workspace, variation: variation)
        return ExperimentEvaluation(
            reason: reason,
            targetEvaluations: context.targetEvaluations,
            experiment: request.experiment,
            variationId: variation.id,
            variationKey: variation.key,
            config: parameterConfiguration
        )
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
