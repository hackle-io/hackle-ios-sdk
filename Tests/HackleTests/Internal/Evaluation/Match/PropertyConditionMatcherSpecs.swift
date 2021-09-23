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

        it("TargetKeyType이 HACKLE_PROPERTY인 경우 match false") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .hackleProperty, name: "test"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [MatchValue(value: "a")])
            )

            // when
            let actual = sut.matches(condition: condition, workspace: MockWorkspace(), user: Hackle.user(id: "test"))

            // then
            expect(actual).to(beFalse())
        }


        it("USER_PROPRTY에 해당하는 값이 없는 경우 match false") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .userProperty, name: "test"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [MatchValue(value: "a")])
            )

            // when
            let actual = sut.matches(condition: condition, workspace: MockWorkspace(), user: Hackle.user(id: "test"))

            // then
            expect(actual).to(beFalse())
        }


        it("USER_PROPRTY에 해당하는 속성값을 가져와서 valueOperator로 매칭한다") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .userProperty, name: "test"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [MatchValue(value: "a")])
            )

            every(valueOperatorMatcher.matchesMock).returns(true)

            // when
            let actual = sut.matches(condition: condition, workspace: MockWorkspace(), user: Hackle.user(id: "test", properties: ["test": "value"]))

            // then
            expect(actual).to(beTrue())
        }
    }
}