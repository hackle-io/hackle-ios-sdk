import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultSegmentMatcherSpecs: QuickSpec {

    override func spec() {

        var userConditionMatcher: ConditionMatcherStub!
        var sut: DefaultSegmentMatcher!

        beforeEach {
            userConditionMatcher = ConditionMatcherStub()
            sut = DefaultSegmentMatcher(userConditionMatcher: userConditionMatcher)
        }

        it("Target 이 비어있으면 match false") {
            // given
            let segment = MockSegment()

            // when
            let actual = try sut.matches(segment: segment, workspace: MockWorkspace(), user: HackleUser.of(userId: "test_id"))

            // then
            expect(actual) == false
        }

        it("매칭되는 Target 이 하나라도 있으면 true") {
            // given
            let segment = segment(
                [true, true, false, true], // false
                [false], // false
                [true, true], // true*
                [true, true, true] // true
            )

            // when
            let actual = try sut.matches(segment: segment, workspace: MockWorkspace(), user: HackleUser.of(userId: "test_id"))

            // then
            expect(actual) == true
            expect(userConditionMatcher.callCount) == 6
        }

        it("매칭되는 Target 이 하나도 없으면 false") {
            // given
            let segment = segment(
                [true, true, true, false], // false
                [false], // false
                [true, false], // false
                [true, false, true] // false
            )

            // when
            let actual = try sut.matches(segment: segment, workspace: MockWorkspace(), user: HackleUser.of(userId: "test_id"))

            // then
            expect(actual) == false
            expect(userConditionMatcher.callCount) == 9
        }

        func segment(_ targetConditions: [Bool]...) -> Segment {
            var targets = [Target]()
            for targetMatches in targetConditions {
                var conditions = [Target.Condition]()
                for conditionMatch in targetMatches {
                    let condition = Target.Condition(key: Target.Key(type: .userProperty, name: "t"), match: Target.Match(type: .match, matchOperator: .contains, valueType: .string, values: [MatchValue(value: "a")]))
                    userConditionMatcher.addResult(condition: condition, isMatches: conditionMatch)
                    conditions.append(condition)
                }
                targets.append(Target(conditions: conditions))
            }
            return MockSegment(targets: targets)
        }
    }

    private class ConditionMatcherStub: ConditionMatcher {

        private var matches = [(Target.Condition, Bool)]()
        var callCount = 0

        func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) throws -> Bool {
            callCount = callCount + 1
            guard let match = matches.first(where: { $0.0 === condition }) else {
                throw HackleError.error("error")
            }
            return match.1
        }

        func addResult(condition: Target.Condition, isMatches: Bool) {
            matches.append((condition, isMatches))
        }
    }
}
