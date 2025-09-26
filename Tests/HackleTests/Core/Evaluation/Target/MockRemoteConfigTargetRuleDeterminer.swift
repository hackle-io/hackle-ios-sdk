import Foundation
import MockingKit
@testable import Hackle

class MockRemoteConfigTargetRuleDeterminer: Mock, RemoteConfigTargetRuleDeterminer {

    lazy var determineTargetRuleOrNilMock = MockFunction(self, determineTargetRuleOrNil)

    func determineTargetRuleOrNil(request: RemoteConfigRequest, context: EvaluatorContext) throws -> RemoteConfigParameter.TargetRule? {
        call(determineTargetRuleOrNilMock, args: (request, context))
    }
}