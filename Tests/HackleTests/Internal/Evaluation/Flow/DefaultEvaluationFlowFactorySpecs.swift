import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultEvaluationFlowFactorySpecs: QuickSpec {
    override func spec() {
        describe("getFlow()") {

            let sut = DefaultEvaluationFlowFactory(manualOverrideStorage: DelegatingManualOverrideStorage(storages: []))

            it("AB_TEST") {

                let actual: EvaluationFlow = sut.getFlow(experimentType: .abTest)

                expect(actual).to(beAnInstanceOf(DefaultEvaluationFlow.self))

                let flow = actual as! DefaultEvaluationFlow
                flow
                    .isDecisionWith(OverrideEvaluator.self)!
                    .isDecisionWith(IdentifierEvaluator.self)!
                    .isDecisionWith(ContainerEvaluator.self)!
                    .isDecisionWith(ExperimentTargetEvaluator.self)!
                    .isDecisionWith(DraftExperimentEvaluator.self)!
                    .isDecisionWith(PausedExperimentEvaluator.self)!
                    .isDecisionWith(CompletedExperimentEvaluator.self)!
                    .isDecisionWith(TrafficAllocateEvaluator.self)!
                    .isEnd()
            }

            it("FEATURE_FLAG") {

                let actual: EvaluationFlow = sut.getFlow(experimentType: .featureFlag)

                expect(actual).to(beAnInstanceOf(DefaultEvaluationFlow.self))

                let flow = actual as! DefaultEvaluationFlow
                flow
                    .isDecisionWith(DraftExperimentEvaluator.self)!
                    .isDecisionWith(PausedExperimentEvaluator.self)!
                    .isDecisionWith(CompletedExperimentEvaluator.self)!
                    .isDecisionWith(OverrideEvaluator.self)!
                    .isDecisionWith(IdentifierEvaluator.self)!
                    .isDecisionWith(TargetRuleEvaluator.self)!
                    .isDecisionWith(DefaultRuleEvaluator.self)!
                    .isEnd()
            }
        }
    }
}
