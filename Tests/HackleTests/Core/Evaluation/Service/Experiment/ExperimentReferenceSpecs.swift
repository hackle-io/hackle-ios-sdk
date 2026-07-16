import Foundation
import Quick
import Nimble
@testable import Hackle

class ExperimentReferenceSpecs: QuickSpec {
    override class func spec() {

        func evaluation(type: ExperimentType, reason: String) -> ExperimentEvaluation {
            ExperimentEvaluation(
                entity: experiment(type: type),
                result: ExperimentEvaluateResult.of(
                    reason: reason,
                    variation: VariationEntity(id: 1, key: "A", isDropped: false, parameterConfiguration: nil)
                )
            )
        }

        it("실험 요청 + AB_TEST + TRAFFIC_ALLOCATED면 BY_TARGETING으로 치환한다") {
            let request = experimentRequest(experiment: experiment(type: .abTest))
            let evaluation = evaluation(type: .abTest, reason: DecisionReason.TRAFFIC_ALLOCATED)

            let resolved = ExperimentReference.resolve(sourceRequest: request, evaluation: evaluation)

            expect(resolved.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED_BY_TARGETING
        }

        it("소스가 실험 요청이 아니면 유지한다") {
            let request = remoteConfigRequest()
            let evaluation = evaluation(type: .abTest, reason: DecisionReason.TRAFFIC_ALLOCATED)

            let resolved = ExperimentReference.resolve(sourceRequest: request, evaluation: evaluation)

            expect(resolved.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED
        }

        it("FEATURE_FLAG면 유지한다") {
            let request = experimentRequest(experiment: experiment(type: .featureFlag))
            let evaluation = evaluation(type: .featureFlag, reason: DecisionReason.TRAFFIC_ALLOCATED)

            let resolved = ExperimentReference.resolve(sourceRequest: request, evaluation: evaluation)

            expect(resolved.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED
        }

        it("TRAFFIC_ALLOCATED가 아니면 유지한다") {
            let request = experimentRequest(experiment: experiment(type: .abTest))
            let evaluation = evaluation(type: .abTest, reason: DecisionReason.OVERRIDDEN)

            let resolved = ExperimentReference.resolve(sourceRequest: request, evaluation: evaluation)

            expect(resolved.experimentResult.reason) == DecisionReason.OVERRIDDEN
        }
    }
}
