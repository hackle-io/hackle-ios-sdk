import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockEvaluator: Evaluator {

    var returns: EvaluateResponse? = nil

    var call: Int = 0

    var recordCount: Int = 0
    private(set) var recordedResponses: [EvaluateResponse] = []

    func evaluate<R>(request: EvaluateRequest, context: EvaluatorContext) throws -> R where R: EvaluateResponse {
        guard let response = returns else {
            throw HackleError.error("nil")
        }
        call = call + 1
        return response as! R
    }

    func record(request: EvaluateRequest, response: EvaluateResponse) {
        recordCount += 1
        recordedResponses.append(response)
    }
}
