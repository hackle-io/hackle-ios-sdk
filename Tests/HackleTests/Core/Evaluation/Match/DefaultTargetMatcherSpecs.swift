import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultTargetMatcherSpecs: QuickSpec {
    override func spec() {
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
            let actual = try sut.matches(request: experimentRequest(), context: Evaluators.context(), target: target)

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
            let actual = try sut.matches(request: experimentRequest(), context: Evaluators.context(), target: target)

            // then
            expect(actual).to(beFalse())
            expect(trueMatcher.callCount).to(equal(3))
            expect(falseMatcher.callCount).to(equal(1))
        }

        describe("anyMatches") {

            it("when targets is empty then returns true") {
                // given
                let sut = DefaultTargetMatcher(conditionMatcherFactory: MockConditionMatcherFactory([]))

                // when
                let actual = try sut.anyMatches(request: experimentRequest(), context: Evaluators.context(), targets: [])

                // then
                expect(actual) == true
            }

            it("when any target matches then return true") {
                // given
                let target = Target(conditions: [self.condition()])
                let targets = [target, target, target, target, target]

                let trueMatcher = MockConditionMatcher(true)
                let falseMatcher = MockConditionMatcher(false)
                let factory = MockConditionMatcherFactory([
                    falseMatcher,
                    falseMatcher,
                    falseMatcher,
                    trueMatcher,
                    falseMatcher
                ])

                let sut = DefaultTargetMatcher(conditionMatcherFactory: factory)

                let actual = try sut.anyMatches(request: experimentRequest(), context: Evaluators.context(), targets: targets)

                // then
                expect(actual) == true
                expect(falseMatcher.callCount) == 3
                expect(trueMatcher.callCount) == 1
            }

            it("when every targets do not match then return false") {
                // given
                let target = Target(conditions: [self.condition()])
                let targets = [target, target, target]

                let falseMatcher = MockConditionMatcher(false)
                let factory = MockConditionMatcherFactory([
                    falseMatcher,
                    falseMatcher,
                    falseMatcher
                ])

                let sut = DefaultTargetMatcher(conditionMatcherFactory: factory)

                let actual = try sut.anyMatches(request: experimentRequest(), context: Evaluators.context(), targets: targets)

                // then
                expect(actual) == false
                expect(falseMatcher.callCount) == 3
            }
        }
    }

    private func condition() -> Target.Condition {
        Target.Condition(key: Target.Key(type: .userProperty, name: "age"), match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 1)]))
    }
}
