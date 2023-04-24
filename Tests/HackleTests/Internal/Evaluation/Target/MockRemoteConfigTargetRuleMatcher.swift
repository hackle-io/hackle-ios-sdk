import Foundation
import Mockery
@testable import Hackle

class MockRemoteConfigTargetRuleMatcher: Mock, RemoteConfigTargetRuleMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(request: RemoteConfigRequest, context: EvaluatorContext, targetRule: RemoteConfigParameter.TargetRule) throws -> Bool {
        call(matchesMock, args: (request, context, targetRule))
    }
}