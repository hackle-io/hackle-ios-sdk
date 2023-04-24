import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockEvaluator: Evaluator {

    var returns: EvaluatorEvaluation!

    var call: Int = 0
    func evaluate<Evaluation>(request: EvaluatorRequest, context: EvaluatorContext) throws -> Evaluation where Evaluation: EvaluatorEvaluation {
        call = call + 1
        return returns as! Evaluation
    }
}