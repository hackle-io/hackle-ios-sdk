//
//  ExperimentEvaluationSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class ExperimentEvaluationSpecs: QuickSpec {
    override class func spec() {
        it("create by Variation") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfigurationId: 99),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfigurationId: 100)
                ]
            )
            let variation = experiment.getVariationOrNil(variationKey: "B")!

            let config = ParameterConfigurationEntity(id: 100, parameters: [:])

            let result = ExperimentEvaluateResult.of(reason: DecisionReason.TRAFFIC_ALLOCATED, variation: variation, config: config)
            let evaluation = ExperimentEvaluation(entity: experiment, result: result)

            expect(evaluation.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(evaluation.experiment as? ExperimentEntity).to(beIdenticalTo(experiment as? ExperimentEntity))
            expect(evaluation.experimentResult.variationId) == variation.id
            expect(evaluation.experimentResult.variationKey) == "B"
            expect(evaluation.experimentResult.config).to(beIdenticalTo(config))
        }

        it("create by Variation - config nil") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfigurationId: nil),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfigurationId: nil)
                ]
            )
            let variation = experiment.getVariationOrNil(variationKey: "B")!

            let result = ExperimentEvaluateResult.of(reason: DecisionReason.TRAFFIC_ALLOCATED, variation: variation, config: nil)
            let evaluation = ExperimentEvaluation(entity: experiment, result: result)

            expect(evaluation.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(evaluation.experiment as? ExperimentEntity).to(beIdenticalTo(experiment as? ExperimentEntity))
            expect(evaluation.experimentResult.variationId) == variation.id
            expect(evaluation.experimentResult.variationKey) == "B"
            expect(evaluation.experimentResult.config).to(beNil())
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

            let result = try ExperimentEvaluateResult.ofDefault(reason: DecisionReason.TRAFFIC_NOT_ALLOCATED, request: request)
            let evaluation = ExperimentEvaluation(entity: experiment, result: result)

            expect(evaluation.experimentResult.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
            expect(evaluation.experiment as? ExperimentEntity).to(beIdenticalTo(experiment as? ExperimentEntity))
            expect(evaluation.experimentResult.variationId) == 320
            expect(evaluation.experimentResult.variationKey) == "A"
            expect(evaluation.experimentResult.config).to(beNil())
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

            let result = try ExperimentEvaluateResult.ofDefault(reason: DecisionReason.TRAFFIC_NOT_ALLOCATED, request: request)
            let evaluation = ExperimentEvaluation(entity: experiment, result: result)

            expect(evaluation.experimentResult.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
            expect(evaluation.experiment as? ExperimentEntity).to(beIdenticalTo(experiment as? ExperimentEntity))
            expect(evaluation.experimentResult.variationId).to(beNil())
            expect(evaluation.experimentResult.variationKey) == "C"
            expect(evaluation.experimentResult.config).to(beNil())
        }
    }
}

func experimentEvaluation(
    reason: String = DecisionReason.TRAFFIC_ALLOCATED,
    experiment: ExperimentConfig = experiment(),
    variationId: Variation.Id? = 1,
    variationKey: Variation.Key = "A",
    config: ParameterConfiguration? = nil
) -> ExperimentEvaluation {
    ExperimentEvaluation(
        entity: experiment,
        result: ExperimentEvaluateResult(
            reason: reason,
            variationId: variationId,
            variationKey: variationKey,
            config: config
        )
    )
}
