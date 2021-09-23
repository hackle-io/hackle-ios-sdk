import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class EvaluationSpecs: QuickSpec {
    override func spec() {
        it("create") {

            expect(Evaluation.of(variation: MockVariation(id: 42, key: "B"), reason: DecisionReason.TARGET_RULE_MATCH))
                .to(equal(Evaluation(variationId: 42, variationKey: "B", reason: DecisionReason.TARGET_RULE_MATCH)))


            let experiment = MockExperiment()
            every(experiment.getVariationByKeyOrNilMock).returns(MockVariation(id: 320, key: "C"))
            expect(Evaluation.of(experiment: experiment, variationKey: "C", reason: DecisionReason.TRAFFIC_ALLOCATED))
                .to(equal(Evaluation(variationId: 320, variationKey: "C", reason: DecisionReason.TRAFFIC_ALLOCATED)))


            let experiment2 = MockExperiment()
            every(experiment2.getVariationByKeyOrNilMock).returns(nil)
            expect(Evaluation.of(experiment: experiment2, variationKey: "C", reason: DecisionReason.TRAFFIC_ALLOCATED))
                .to(equal(Evaluation(variationId: nil, variationKey: "C", reason: DecisionReason.TRAFFIC_ALLOCATED)))
        }
    }
}