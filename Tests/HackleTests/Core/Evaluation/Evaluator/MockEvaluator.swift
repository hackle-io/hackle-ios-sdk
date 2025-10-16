import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockEvaluator: Evaluator {

    var returns: EvaluatorEvaluation? = nil

    var call: Int = 0

    func evaluate<Evaluation>(request: EvaluatorRequest, context: EvaluatorContext) throws -> Evaluation where Evaluation: EvaluatorEvaluation {
        guard let evaluation = returns else {
            throw HackleError.error("nil")
        }
        call = call + 1
        return evaluation as! Evaluation
    }
}