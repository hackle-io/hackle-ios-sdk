import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class UserConditionMatcherSpecs: QuickSpec {
    override func spec() {

        var userValueResolver: MockUserValueResolver!
        var valueOperatorMatcher: MockValueOperatorMatcher!
        var sut: UserConditionMatcher!

        beforeEach {
            userValueResolver = MockUserValueResolver()
            valueOperatorMatcher = MockValueOperatorMatcher()
            sut = UserConditionMatcher(userValueResolver: userValueResolver, valueOperatorMatcher: valueOperatorMatcher)
        }

        it("key 에 해당하는 값이 없는 경우 match false") {
            // given
            every(userValueResolver.resolveOrNilMock).returns(nil)
            let condition = Target.Condition(
                key: Target.Key(type: .hackleProperty, name: "osName"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "iOS")])
            )

            // when
            let actual = try sut.matches(condition: condition, workspace: MockWorkspace(), user: HackleUser.of(userId: "test_user_id"))

            // then
            expect(actual).to(beFalse())
        }

        it("key 에 해당하는 UserValue 로 매칭한다") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .hackleProperty, name: "osName"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "iOS")])
            )

            let user = HackleUser.of(user: Hackle.user(id: "test_user_id"), hackleProperties: ["osName": "iOS"])

            every(userValueResolver.resolveOrNilMock).returns("iOS")
            every(valueOperatorMatcher.matchesMock).returns(true)

            // when
            let actual = try sut.matches(condition: condition, workspace: MockWorkspace(), user: user)

            // then
            expect(actual).to(beTrue())
        }
    }
}
