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

        it("key 에 해당하는 UserValue 로 매칭한다") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .hackleProperty, name: "osName"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "iOS")])
            )

            let user = HackleUser.of(user: Hackle.user(id: "test_user_id"), hackleProperties: ["osName": "iOS"])

            every(userValueResolver.resolveOrNilMock).returns("iOS")
            every(valueOperatorMatcher.matchesMock).returns(true)

            let request = experimentRequest(user: user)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual).to(beTrue())
        }
    }
}
