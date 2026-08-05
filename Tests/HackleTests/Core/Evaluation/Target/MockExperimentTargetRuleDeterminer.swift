import Foundation
import MockingKit
@testable import Hackle


class MockExperimentTargetRuleDeterminer: Mock, ExperimentTargetRuleDeterminer {

    lazy var determineTargetRuleOrNilMock = MockFunction(self, determineTargetRuleOrNil)

    func determineTargetRuleOrNil(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> TargetRule? {
        call(determineTargetRuleOrNilMock, args: (request, context))
    }
}