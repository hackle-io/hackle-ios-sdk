import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultTargetMatcherSpecs: QuickSpec {
    override func spec() {

        let user = Hackle.user(id: "test")

        it("타겟의 모든 조건이 일치하면 true") {
            // given
            let target = Target(conditions: [
                self.condition(),
                self.condition(),
                self.condition(),
                self.condition(),
                self.condition()
            ])

            let matcher = MockConditionMatcher(true)
            let factory = MockConditionMatcherFactory([
                matcher,
                matcher,
                matcher,
                matcher,
                matcher
            ])
            let sut = DefaultTargetMatcher(conditionMatcherFactory: factory)

            // when
            let actual = sut.matches(target: target, workspace: MockWorkspace(), user: user)

            // then
            expect(actual).to(beTrue())
            expect(matcher.callCount).to(equal(5))
        }

        it("타겟의 조건중 하나라도 일치하지 않으면 false") {
            // given
            let target = Target(conditions: [
                self.condition(),
                self.condition(),
                self.condition(),
                self.condition(),
                self.condition(),
                self.condition()
            ])

            let trueMatcher = MockConditionMatcher(true)
            let falseMatcher = MockConditionMatcher(false)
            let factory = MockConditionMatcherFactory([
                trueMatcher,
                trueMatcher,
                trueMatcher,
                falseMatcher,
                trueMatcher,
                falseMatcher
            ])

            let sut = DefaultTargetMatcher(conditionMatcherFactory: factory)

            // when
            let actual = sut.matches(target: target, workspace: MockWorkspace(), user: user)

            // then
            expect(actual).to(beFalse())
            expect(trueMatcher.callCount).to(equal(3))
            expect(falseMatcher.callCount).to(equal(1))
        }
    }

    private func condition() -> Target.Condition {
        Target.Condition(key: Target.Key(type: .userProperty, name: "age"), match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [MatchValue(value: 1)]))
    }
}