import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockEvaluationFlow: Mock, EvaluationFlow {

    lazy var evaluateMock = MockFunction(self, evaluate)

    func evaluate(workspace: Workspace, experiment: Experiment, user: User, defaultVariationKey: Variation.Key) throws -> Evaluation {
        call(evaluateMock, args: (workspace, experiment, user, defaultVariationKey))
    }
}

extension DefaultEvaluationFlow {

    func isDecisionWith<T: FlowEvaluator>(_ expectedType: T.Type) -> DefaultEvaluationFlow? {
        switch self {
        case .end:
            fail()
            return nil
        case .decision(let flowEvaluator, let nextFlow):
            expect(flowEvaluator).to(beAnInstanceOf(expectedType))
            return (nextFlow as! DefaultEvaluationFlow)
        }
    }

    func isDecisionWith<T: FlowEvaluator>(_ expectedFlowEvaluator: T) -> DefaultEvaluationFlow? {
        switch self {
        case .end:
            fatalError("must be decision")
        case .decision(let flowEvaluator, let nextFlow):
            expect(flowEvaluator).to(beIdenticalTo(expectedFlowEvaluator))
            return (nextFlow as! DefaultEvaluationFlow)
        }
    }

    func isEnd() {
        switch self {
        case .end:
            return
        case .decision:
            fatalError("must be end")
        }
    }
}