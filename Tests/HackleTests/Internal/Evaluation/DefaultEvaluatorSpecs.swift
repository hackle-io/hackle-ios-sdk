import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultEvaluatorSpecs: QuickSpec {
    override func spec() {

        it("evaluationFlowFactory에서 ExperimentType으로 Flow를 가져와서 평가한다") {

            // given
            let evaluationFlow = MockEvaluationFlow()
            let evaluation = Evaluation(variationId: 42, variationKey: "B", reason: DecisionReason.DEFAULT_RULE)
            every(evaluationFlow.evaluateMock).returns(evaluation)

            let factory = EvaluationFlowFactoryStub(flow: evaluationFlow)

            let sut = DefaultEvaluator(evaluationFlowFactory: factory)

            // when
            let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(), user: Hackle.user(id: "test"), defaultVariationKey: "A")

            // then
            expect(actual).to(equal(evaluation))
        }
    }
}

private class EvaluationFlowFactoryStub: EvaluationFlowFactory {
    private let flow: EvaluationFlow

    init(flow: EvaluationFlow) {
        self.flow = flow
    }

    func getFlow(experimentType: ExperimentType) -> EvaluationFlow {
        flow
    }
}