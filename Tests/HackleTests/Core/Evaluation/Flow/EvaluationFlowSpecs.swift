import Foundation
import Quick
import Nimble
@testable import Hackle


class EvaluationFlowSpecs: QuickSpec {
    override class func spec() {

        describe("evaluate") {

            it("when end of flow then returns nil") {
                let flow: ExperimentLocalEvaluationFlow = ExperimentLocalEvaluationFlow.end()
                let actual = try flow.evaluate(request: experimentRequest(), context: Evaluators.context())
                expect(actual).to(beNil())
            }

            it("when flow need decision then evaluate flow") {
                // given
                let evaluation = experimentEvaluation()
                let flow: ExperimentLocalEvaluationFlow = ExperimentLocalEvaluationFlow.decision(evaluator: FlowEvaluatorStub(evaluation: evaluation), nextFlow: .end())
                let actual = try flow.evaluate(request: experimentRequest(), context: Evaluators.context())
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        it("of") {
            let f1 = NextFlowEvaluator()
            let f2 = NextFlowEvaluator()
            let f3 = NextFlowEvaluator()

            let flow: ExperimentLocalEvaluationFlow = ExperimentLocalEvaluationFlow.of(f1, f2, f3)

            flow
                .isDecisionWith(f1)!
                .isDecisionWith(f2)!
                .isDecisionWith(f3)!
                .isEnd()
        }

        it("+") {
            let fe1 = NextFlowEvaluator()
            let fe2 = NextFlowEvaluator()
            let fe3 = NextFlowEvaluator()
            let fe4 = NextFlowEvaluator()

            let f1: ExperimentLocalEvaluationFlow = ExperimentLocalEvaluationFlow.of(fe1, fe2)
            let f2: ExperimentLocalEvaluationFlow = ExperimentLocalEvaluationFlow.of(fe3, fe4)

            let f: ExperimentLocalEvaluationFlow = f1 + f2

            f
                .isDecisionWith(fe1)!
                .isDecisionWith(fe2)!
                .isDecisionWith(fe3)!
                .isDecisionWith(fe4)!
                .isEnd()
        }
    }
}
