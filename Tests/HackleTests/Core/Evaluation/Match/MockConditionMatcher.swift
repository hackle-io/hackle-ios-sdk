import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockConditionMatcher: ConditionMatcher {

    private let isMatches: Bool
    var callCount = 0

    init(_ isMatches: Bool) {
        self.isMatches = isMatches
    }

    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        callCount = callCount + 1
        return isMatches
    }
}