import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


extension EvaluationFlow {

    static func create<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        _ evaluation: Evaluation
    ) -> EvaluationFlow<Request, Evaluation> {
        of(FlowEvaluatorStub(evaluation: evaluation))
    }

    func isDecisionWith<T: FlowEvaluator>(_ expectedType: T.Type) -> EvaluationFlow? {
        guard let evaluator = evaluator, let nextFlow = nextFlow else {
            fail("Expected: \(expectedType)\nActual: EvaluationFlow.end")
            return nil
        }
        expect(evaluator).to(beAnInstanceOf(expectedType))
        return nextFlow
    }

    func isDecisionWith<T: FlowEvaluator>(_ expectedFlowEvaluator: T) -> EvaluationFlow? {
        guard let evaluator = evaluator, let nextFlow = nextFlow else {
            fail("Expected: \(expectedFlowEvaluator)\nActual: EvaluationFlow.end")
            return nil
        }
        expect(evaluator).to(beIdenticalTo(expectedFlowEvaluator))
        return nextFlow
    }

    func isEnd() {
        guard evaluator == nil, nextFlow == nil else {
            fail("Expected: EvaluationFlow.end\nActual: \(evaluator.orNil)")
            return
        }
    }
}
