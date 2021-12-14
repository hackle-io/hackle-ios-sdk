import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class PropertyConditionMatcherSpecs: QuickSpec {
    override func spec() {

        var valueOperatorMatcher: MockValueOperatorMatcher!
        var sut: PropertyConditionMatcher!

        beforeEach {
            valueOperatorMatcher = MockValueOperatorMatcher()
            sut = PropertyConditionMatcher(valueOperatorMatcher: valueOperatorMatcher)
        }

        context("TargetKeyType 이 HackleProperty 인 경우") {

            it("해당하는 값이 없는 경우 match false") {
                // given
                let condition = Target.Condition(
                    key: Target.Key(type: .hackleProperty, name: "osName"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [MatchValue(value: "iOS")])
                )

                // when
                let actual = sut.matches(condition: condition, workspace: MockWorkspace(), user: HackleUser.of(userId: "test_user_id"))

                // then
                expect(actual).to(beFalse())
            }

            it("해당 하는 속성 값이 있는 경우 valueOperator 로 매칭한다") {
                // given
                let condition = Target.Condition(
                    key: Target.Key(type: .hackleProperty, name: "osName"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [MatchValue(value: "iOS")])
                )

                let user = HackleUser.of(user: Hackle.user(id: "test_user_id"), hackleProperties: ["osName": "iOS"])
                every(valueOperatorMatcher.matchesMock).returns(true)

                // when
                let actual = sut.matches(condition: condition, workspace: MockWorkspace(), user: user)

                // then
                expect(actual).to(beTrue())
            }
        }

        context("TargetKeyType 이 UserProperty 인 경우") {
            it("해당하는 값이 없는 경우 match false") {
                // given
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "test"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [MatchValue(value: "a")])
                )

                // when
                let actual = sut.matches(condition: condition, workspace: MockWorkspace(), user: HackleUser.of(userId: "test"))

                // then
                expect(actual).to(beFalse())
            }

            it("해당 하는 속성 값이 있는 경우 valueOperator 로 매칭한다") {
                // given
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "test"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [MatchValue(value: "a")])
                )

                every(valueOperatorMatcher.matchesMock).returns(true)
                let user = HackleUser.of(user: Hackle.user(id: "test", properties: ["test": "value"]), hackleProperties: ["osName": "iOS"])

                // when
                let actual = sut.matches(condition: condition, workspace: MockWorkspace(), user: user)

                // then
                expect(actual).to(beTrue())
            }
        }
    }
}
