import Foundation
import Nimble
import Quick
@testable import Hackle

class CohortConditionMatcherSpecs: QuickSpec {
    override func spec() {

        let valueOperatorMatcher = DefaultValueOperatorMatcher(
            valueMatcherFactory: ValueMatcherFactory(),
            operatorMatcherFactory: OperatorMatcherFactory()
        )

        let sut = CohortConditionMatcher(valueOperatorMatcher: valueOperatorMatcher)

        it("when condition key type is not COHORT then throw error") {
            let request = experimentRequest()
            let condition = Target.Condition(
                key: Target.Key(type: .userProperty, name: "age"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 42)])
            )

            expect(try sut.matches(request: request, context: Evaluators.context(), condition: condition))
                .to(throwError(HackleError.error("Unsupported TargetKeyType [userProperty]")))
        }

        it("when user cohorts is empty then return false") {
            // given
            let request = experimentRequest(
                user: HackleUser.builder().identifier(.id, "user").build()
            )
            let condition = Target.Condition(
                key: Target.Key(type: .cohort, name: "COHORT"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 42)])
            )

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == false
        }

        it("when all user cohorts do not matched then return false") {
            // given
            let request = experimentRequest(
                user: HackleUser.builder()
                    .identifier(.id, "user")
                    .cohort(Cohort(id: 100))
                    .cohort(Cohort(id: 101))
                    .cohort(Cohort(id: 102))
                    .build()
            )
            let condition = Target.Condition(
                key: Target.Key(type: .cohort, name: "COHORT"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 42)])
            )

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == false
        }

        it("when any of user cohorts matched then return true") {
            // given
            let request = experimentRequest(
                user: HackleUser.builder()
                    .identifier(.id, "user")
                    .cohort(Cohort(id: 100))
                    .cohort(Cohort(id: 101))
                    .cohort(Cohort(id: 102))
                    .build()
            )
            let condition = Target.Condition(
                key: Target.Key(type: .cohort, name: "COHORT"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 42), HackleValue(value: 102)])
            )

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == true
        }
    }
}
