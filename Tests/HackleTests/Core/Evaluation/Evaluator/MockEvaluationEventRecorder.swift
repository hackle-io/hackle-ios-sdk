import Foundation
import MockingKit
@testable import Hackle

class MockEvaluationEventRecorder: Mock, EvaluationEventRecorder {
    lazy var recordMock = MockFunction(self, record)

    func record(request: EvaluatorRequest, evaluation: EvaluatorEvaluation) {
        call(recordMock, args: (request, evaluation))
    }
}
