import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockTargetMatcher: Mock, TargetMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(request: EvaluatorRequest, context: EvaluatorContext, target: Target) throws -> Bool {
        call(matchesMock, args: (request, context, target))
    }
}

class TargetMatcherStub: TargetMatcher {

    var isMatches: [Bool] {
        didSet {
            callCount = 0
        }
    }
    var callCount = 0

    init(isMatches: [Bool] = []) {
        self.isMatches = isMatches
    }

    static func of(_ isMatches: Bool...) -> TargetMatcherStub {
        TargetMatcherStub(isMatches: isMatches)
    }

    func matches(request: EvaluatorRequest, context: EvaluatorContext, target: Target) throws -> Bool {
        let isMatch = isMatches[callCount]
        callCount += 1
        return isMatch
    }
}
