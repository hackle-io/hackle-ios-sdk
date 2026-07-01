import Foundation
import MockingKit
@testable import Hackle


class MockExperimentTargetDeterminer: Mock, ExperimentTargetDeterminer {

    lazy var isUserInExperimentTargetMock = MockFunction(self, isUserInExperimentTarget)

    func isUserInExperimentTarget(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        call(isUserInExperimentTargetMock, args: (request, context))
    }
}