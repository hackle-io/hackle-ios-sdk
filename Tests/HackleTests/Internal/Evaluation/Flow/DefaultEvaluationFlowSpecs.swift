import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultEvaluationFlowSpecs: QuickSpec {
    override func spec() {


        describe("evaluate") {
            it("end 인 경우 기본 그룹으로 평가") {
                // given
                let experiment = MockExperiment()
                every(experiment.getVariationByKeyOrNilMock).returns(MockVariation(id: 42, key: "J"))

                // when
                let actual = try DefaultEvaluationFlow.end.evaluate(workspace: MockWorkspace(), experiment: experiment, user: HackleUser.of(userId: "test"), defaultVariationKey: "J")

                // then
                expect(actual.variationId) == 42
                expect(actual.variationKey) == "J"
                expect(actual.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
            }

            it("decision인 경우 flowEvaluator를 호출한다") {
                // given
                let flowEvaluator = MockFlowEvaluator()
                let nextFlow = MockEvaluationFlow()

                let evaluation = Evaluation(variationId: 42, variationKey: "E", reason: DecisionReason.TRAFFIC_ALLOCATED)
                every(flowEvaluator.evaluateMock).returns(evaluation)

                let sut = DefaultEvaluationFlow.decision(flowEvaluator: flowEvaluator, nextFlow: nextFlow)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(), user: HackleUser.of(userId: "test"), defaultVariationKey: "J")

                // then
                expect(actual) == evaluation
                verify(exactly: 1) {
                    flowEvaluator.evaluateMock
                }
            }
        }

        describe("of") {

            let f1 = MockFlowEvaluator()
            let f2 = MockFlowEvaluator()
            let f3 = MockFlowEvaluator()

            let flow = DefaultEvaluationFlow.of(f1, f2, f3)

            expect(flow).to(beAnInstanceOf(DefaultEvaluationFlow.self))

            (flow as! DefaultEvaluationFlow)
                .isDecisionWith(f1)!
                .isDecisionWith(f2)!
                .isDecisionWith(f3)!
                .isEnd()
        }
    }
}