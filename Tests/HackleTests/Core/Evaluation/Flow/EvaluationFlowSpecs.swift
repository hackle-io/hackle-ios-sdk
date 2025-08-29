import Foundation
import Quick
import Nimble
@testable import Hackle


class EvaluationFlowSpecs: QuickSpec {
    override func spec() {

        describe("evaluate") {

            it("when end of flow then returns nil") {
                let flow: ExperimentFlow = ExperimentFlow.end()
                let actual = try flow.evaluate(request: experimentRequest(), context: Evaluators.context())
                expect(actual).to(beNil())
            }

            it("when flow need decision then evaluate flow") {
                // given
                let evaluation = experimentEvaluation()
                let flow: ExperimentFlow = ExperimentFlow.decision(evaluator: FlowEvaluatorStub(evaluation: evaluation), nextFlow: .end())
                let actual = try flow.evaluate(request: experimentRequest(), context: Evaluators.context())
                expect(actual).to(beIdenticalTo(evaluation))
            }
        }

        it("of") {
            let f1 = NextFlowEvaluator()
            let f2 = NextFlowEvaluator()
            let f3 = NextFlowEvaluator()

            let flow: ExperimentFlow = ExperimentFlow.of(f1, f2, f3)

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

            let f1: ExperimentFlow = ExperimentFlow.of(fe1, fe2)
            let f2: ExperimentFlow = ExperimentFlow.of(fe3, fe4)

            let f: ExperimentFlow = f1 + f2

            f
                .isDecisionWith(fe1)!
                .isDecisionWith(fe2)!
                .isDecisionWith(fe3)!
                .isDecisionWith(fe4)!
                .isEnd()
        }
    }
}
