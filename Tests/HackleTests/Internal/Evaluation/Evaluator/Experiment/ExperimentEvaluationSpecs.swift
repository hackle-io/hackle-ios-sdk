//
//  ExperimentEvaluationSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class ExperimentEvaluationSpecs: QuickSpec {
    override func spec() {
        it("create by Variation") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfigurationId: 99),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfigurationId: 100)
                ]
            )
            let variation = experiment.getVariationOrNil(variationKey: "B")!

            let config = ParameterConfigurationEntity(id: 100, parameters: [:])
            let workspace = MockWorkspace()
            every(workspace.getParameterConfigurationOrNilMock).returns(config)

            let user = HackleUser.builder().build()
            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment, defaultVariation: "H")

            let context = Evaluators.context()
            context.add(experimentEvaluation())

            let evaluation = try ExperimentEvaluation.of(request: request, context: context, variation: variation, reason: DecisionReason.TRAFFIC_ALLOCATED)

            expect(evaluation.reason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(evaluation.targetEvaluations.count) == 1
            expect(evaluation.experiment).to(beIdenticalTo(experiment))
            expect(evaluation.variationId) == variation.id
            expect(evaluation.variationKey) == "B"
            expect(evaluation.config).to(beIdenticalTo(config))
        }

        it("create by Variation - config nil") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfigurationId: nil),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfigurationId: nil)
                ]
            )
            let variation = experiment.getVariationOrNil(variationKey: "B")!

            let workspace = MockWorkspace()
            every(workspace.getParameterConfigurationOrNilMock).returns(nil)

            let user = HackleUser.builder().build()
            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment, defaultVariation: "H")

            let context = Evaluators.context()
            context.add(experimentEvaluation())

            let evaluation = try ExperimentEvaluation.of(request: request, context: context, variation: variation, reason: DecisionReason.TRAFFIC_ALLOCATED)

            expect(evaluation.reason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(evaluation.targetEvaluations.count) == 1
            expect(evaluation.experiment).to(beIdenticalTo(experiment))
            expect(evaluation.variationId) == variation.id
            expect(evaluation.variationKey) == "B"
            expect(evaluation.config).to(beNil())
        }

        it("create by Variation - config not found") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfigurationId: 99),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfigurationId: 100)
                ]
            )
            let variation = experiment.getVariationOrNil(variationKey: "B")!

            let workspace = MockWorkspace()
            every(workspace.getParameterConfigurationOrNilMock).returns(nil)

            let user = HackleUser.builder().build()
            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment, defaultVariation: "H")

            let context = Evaluators.context()
            context.add(experimentEvaluation())

            expect(try ExperimentEvaluation.of(request: request, context: context, variation: variation, reason: DecisionReason.TRAFFIC_ALLOCATED))
                .to(throwError(HackleError.error("ParameterConfiguration[100]")))
        }

        it("create by default") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfigurationId: nil),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfigurationId: nil)
                ]
            )

            let workspace = MockWorkspace()

            let user = HackleUser.builder().build()
            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment, defaultVariation: "A")


            let evaluation = try ExperimentEvaluation.ofDefault(request: request, context: Evaluators.context(), reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)

            expect(evaluation.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
            expect(evaluation.targetEvaluations.count) == 0
            expect(evaluation.experiment).to(beIdenticalTo(experiment))
            expect(evaluation.variationId) == 320
            expect(evaluation.variationKey) == "A"
            expect(evaluation.config).to(beNil())
        }

        it("create by default - variation null") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfigurationId: nil),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfigurationId: nil)
                ]
            )

            let workspace = MockWorkspace()

            let user = HackleUser.builder().build()
            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment, defaultVariation: "C")


            let evaluation = try ExperimentEvaluation.ofDefault(request: request, context: Evaluators.context(), reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)

            expect(evaluation.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
            expect(evaluation.targetEvaluations.count) == 0
            expect(evaluation.experiment).to(beIdenticalTo(experiment))
            expect(evaluation.variationId).to(beNil())
            expect(evaluation.variationKey) == "C"
            expect(evaluation.config).to(beNil())
        }
    }
}

func experimentEvaluation(
    reason: String = DecisionReason.TRAFFIC_ALLOCATED,
    targetEvaluations: [EvaluatorEvaluation] = [],
    experiment: Experiment = experiment(),
    variationId: Variation.Id? = 1,
    variationKey: Variation.Key = "A",
    config: ParameterConfiguration? = nil
) -> ExperimentEvaluation {
    ExperimentEvaluation(
        reason: reason,
        targetEvaluations: targetEvaluations,
        experiment: experiment,
        variationId: variationId,
        variationKey: variationKey,
        config: config
    )
}