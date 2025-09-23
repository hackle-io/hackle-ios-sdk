import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockConditionMatcherFactory: ConditionMatcherFactory {

    private var mockMatchers: [ConditionMatcher]
    private var index = 0

    init(_ mockMatchers: [ConditionMatcher]) {
        self.mockMatchers = mockMatchers
    }

    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher {
        let matcher = mockMatchers[index]
        index = index + 1
        return matcher
    }
}