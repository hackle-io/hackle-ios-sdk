import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockTargetMatcher: Mock, TargetMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(request: EvaluatorRequest, context: EvaluatorContext, target: Target) throws -> Bool {
        call(matchesMock, args: (request, context, target))
    }
}