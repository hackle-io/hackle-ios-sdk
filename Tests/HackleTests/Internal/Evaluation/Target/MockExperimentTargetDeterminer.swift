import Foundation
import Mockery
@testable import Hackle


class MockExperimentTargetDeterminer: Mock, ExperimentTargetDeterminer {

    lazy var isUserInExperimentTargetMock = MockFunction(self, isUserInExperimentTarget)

    func isUserInExperimentTarget(request: ExperimentRequest, context: EvaluatorContext) throws -> Bool {
        call(isUserInExperimentTargetMock, args: (request, context))
    }
}