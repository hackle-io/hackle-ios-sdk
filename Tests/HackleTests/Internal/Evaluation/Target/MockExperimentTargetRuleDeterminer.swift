import Foundation
import Mockery
@testable import Hackle


class MockExperimentTargetRuleDeterminer: Mock, ExperimentTargetRuleDeterminer {

    lazy var determineTargetRuleOrNilMock = MockFunction(self, determineTargetRuleOrNil)

    func determineTargetRuleOrNil(request: ExperimentRequest, context: EvaluatorContext) throws -> TargetRule? {
        call(determineTargetRuleOrNilMock, args: (request, context))
    }
}