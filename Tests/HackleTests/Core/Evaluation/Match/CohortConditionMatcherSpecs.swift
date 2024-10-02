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

        it("matches") {
            func check(type: Target.MatchType, userCohorts: [Cohort.Id], cohorts: [Cohort.Id], expected: Bool) throws {
                let request = experimentRequest(
                    user: HackleUser.builder()
                        .identifier(.id, "user")
                        .cohorts(userCohorts.map({ Cohort(id: $0) }))
                        .build()
                )
                let condition = Target.Condition(
                    key: Target.Key(type: .cohort, name: "COHORT"),
                    match: Target.Match(type: type, matchOperator: ._in, valueType: .number, values: cohorts.map({ HackleValue(value: $0) }))
                )

                let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

                expect(actual) == expected
            }

            // UserCohort[] 는 Cohort[1] 중 하나
            try check(type: .match, userCohorts: [], cohorts: [1], expected: false)

            // UserCohort[1] 는 Cohort[1] 중 하나
            try check(type: .match, userCohorts: [1], cohorts: [1], expected: true)

            // UserCohort[1] 는 Cohort[1, 2] 중 하나
            try check(type: .match, userCohorts: [1], cohorts: [1, 2], expected: true)

            // UserCohort[2] 는 Cohort[1, 2] 중 하나
            try check(type: .match, userCohorts: [2], cohorts: [1, 2], expected: true)

            // UserCohort[1] 는 Cohort[2] 중 하나
            try check(type: .match, userCohorts: [1], cohorts: [2], expected: false)

            // UserCohort[1] 는 Cohort[2, 3] 중 하나
            try check(type: .match, userCohorts: [1], cohorts: [2, 3], expected: false)

            // UserCohort[1, 2] 는 Cohort[1] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [1], expected: true)

            // UserCohort[1, 2] 는 Cohort[2] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [2], expected: true)

            // UserCohort[1, 2] 는 Cohort[3] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [3], expected: false)

            // UserCohort[1, 2] 는 Cohort[1, 2] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [1, 2], expected: true)

            // UserCohort[1, 2] 는 Cohort[1, 3] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [1, 3], expected: true)

            // UserCohort[1, 2] 는 Cohort[2, 3] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [2, 3], expected: true)

            // UserCohort[1, 2] 는 Cohort[3, 2] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [3, 2], expected: true)

            // UserCohort[1, 2] 는 Cohort[3, 4] 중 하나
            try check(type: .match, userCohorts: [1, 2], cohorts: [3, 4], expected: false)

            // UserCohort[] 는 Cohort[1] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [], cohorts: [1], expected: true)

            // UserCohort[1] 는 Cohort[1] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1], cohorts: [1], expected: false)

            // UserCohort[1] 는 Cohort[1, 2] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1], cohorts: [1, 2], expected: false)

            // UserCohort[2] 는 Cohort[1, 2] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [2], cohorts: [1, 2], expected: false)

            // UserCohort[1] 는 Cohort[2] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1], cohorts: [2], expected: true)

            // UserCohort[1] 는 Cohort[2, 3] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1], cohorts: [2, 3], expected: true)

            // UserCohort[1, 2] 는 Cohort[1] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [1], expected: false)

            // UserCohort[1, 2] 는 Cohort[2] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [2], expected: false)

            // UserCohort[1, 2] 는 Cohort[3] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [3], expected: true)

            // UserCohort[1, 2] 는 Cohort[1, 2] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [1, 2], expected: false)

            // UserCohort[1, 2] 는 Cohort[1, 3] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [1, 3], expected: false)

            // UserCohort[1, 2] 는 Cohort[2, 3] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [2, 3], expected: false)

            // UserCohort[1, 2] 는 Cohort[3, 2] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [3, 2], expected: false)

            // UserCohort[1, 2] 는 Cohort[3, 4] 중 하나가 아닌
            try check(type: .notMatch, userCohorts: [1, 2], cohorts: [3, 4], expected: true)
        }
    }
}
