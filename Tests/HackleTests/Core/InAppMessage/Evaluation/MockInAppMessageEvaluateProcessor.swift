import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageEvaluateProcessor: Mock, InAppMessageEvaluateProcessor {
    lazy var processMock = MockFunction.throwable(self, process)

    func process(type: InAppMessageEvaluateScope, request: InAppMessageEligibilityLocalEvaluateRequest) throws -> InAppMessageEligibilityEvaluation {
        return try call(processMock, args: (type, request))
    }
}


class InAppMessageEvaluateProcessorStub: InAppMessageEvaluateProcessor {
    var evaluations = [InAppMessageEligibilityEvaluation]() {
        didSet {
            count = 0
        }
    }

    var count = 0

    func process(type: InAppMessageEvaluateScope, request: InAppMessageEligibilityLocalEvaluateRequest) throws -> InAppMessageEligibilityEvaluation {
        let evaluation = evaluations[count]
        count += 1
        return evaluation
    }
}