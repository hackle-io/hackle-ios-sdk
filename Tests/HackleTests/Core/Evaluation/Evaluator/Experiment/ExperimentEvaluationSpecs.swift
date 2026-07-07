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
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfiguration: ParameterConfigurationEntity(id: 99, parameters: [:])),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfiguration: ParameterConfigurationEntity(id: 100, parameters: [:]))
                ]
            )
            let variation = experiment.getVariationOrNil(variationKey: "B")!

            let result = ExperimentEvaluateResult.of(reason: DecisionReason.TRAFFIC_ALLOCATED, variation: variation)
            let evaluation = ExperimentEvaluation(entity: experiment, result: result)

            expect(evaluation.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(evaluation.experiment as? ExperimentEntity).to(beIdenticalTo(experiment as? ExperimentEntity))
            expect(evaluation.experimentResult.variation.id) == variation.id
            expect(evaluation.experimentResult.variation.key) == "B"
            expect(evaluation.experimentResult.variation.parameterConfiguration?.id) == 100
        }

        it("create by Variation - config nil") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfiguration: nil),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfiguration: nil)
                ]
            )
            let variation = experiment.getVariationOrNil(variationKey: "B")!

            let result = ExperimentEvaluateResult.of(reason: DecisionReason.TRAFFIC_ALLOCATED, variation: variation)
            let evaluation = ExperimentEvaluation(entity: experiment, result: result)

            expect(evaluation.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(evaluation.experiment as? ExperimentEntity).to(beIdenticalTo(experiment as? ExperimentEntity))
            expect(evaluation.experimentResult.variation.id) == variation.id
            expect(evaluation.experimentResult.variation.key) == "B"
            expect(evaluation.experimentResult.variation.parameterConfiguration).to(beNil())
        }

        it("create by control") {
            let experiment = experiment(id: 42, key: 50,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfiguration: nil),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfiguration: nil)
                ]
            )

            let workspace = MockWorkspace()
            let user = HackleUser.builder().build()
            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment)

            let result = try ExperimentEvaluateResult.ofControl(reason: DecisionReason.TRAFFIC_NOT_ALLOCATED, request: request)
            let evaluation = ExperimentEvaluation(entity: experiment, result: result)

            expect(evaluation.experimentResult.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
            expect(evaluation.experiment as? ExperimentEntity).to(beIdenticalTo(experiment as? ExperimentEntity))
            expect(evaluation.experimentResult.variation.id) == 320
            expect(evaluation.experimentResult.variation.key) == "A"
            expect(evaluation.experimentResult.variation.parameterConfiguration).to(beNil())
        }

        // 회귀 ①: ofControl 은 항상 컨트롤 그룹(A) 의 variation 을 반환하고, A 가 없으면 예외를 던진다.
        it("ofControl 은 컨트롤 그룹(A) 의 variation 을 반환한다") {
            let exp = experiment(
                type: .abTest,
                status: .draft,
                variations: [
                    VariationEntity(id: 320, key: "A", isDropped: false, parameterConfiguration: ParameterConfigurationEntity(id: 99, parameters: [:])),
                    VariationEntity(id: 321, key: "B", isDropped: false, parameterConfiguration: nil)
                ]
            )
            let request = experimentRequest(experiment: exp)

            let result = try ExperimentEvaluateResult.ofControl(reason: DecisionReason.EXPERIMENT_DRAFT, request: request)

            expect(result.reason) == DecisionReason.EXPERIMENT_DRAFT
            expect(result.variation.id) == 320
            expect(result.variation.key) == "A"
            expect(result.variation.parameterConfiguration?.id) == 99
        }

        it("ofControl 은 A variation 이 없으면 예외를 던진다") {
            let exp = experiment(
                type: .abTest,
                status: .draft,
                variations: [VariationEntity(id: 321, key: "B", isDropped: false, parameterConfiguration: nil)]
            )
            let request = experimentRequest(experiment: exp)

            expect(try ExperimentEvaluateResult.ofControl(reason: DecisionReason.EXPERIMENT_DRAFT, request: request))
                .to(throwError())
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
            variation: VariationEntity(id: variationId ?? 0, key: variationKey, isDropped: false, parameterConfiguration: config)
        )
    )
}
