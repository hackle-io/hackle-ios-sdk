import Foundation
import Nimble
import Quick
@testable import Hackle


class UserCohortSpecs: QuickSpec {
    override func spec() {
        it("UserCohorts") {
            expect(UserCohorts.empty().rawCohorts.count) == 0

            let userCohorts = UserCohorts.builder()
                .put(cohort: UserCohort(
                    identifier: Identifier(type: "$id", value: "id"),
                    cohorts: [Cohort(id: 1), Cohort(id: 2)])
                )
                .putAll(cohorts: UserCohorts.builder()
                    .put(cohort: UserCohort(
                        identifier: Identifier(type: "$userId", value: "user_id"),
                        cohorts: [Cohort(id: 3)])
                    )
                    .build()
                )
                .build()

            // rawCohorts
            expect(userCohorts.rawCohorts.count) === 3

            // get
            expect(userCohorts[Identifier(type: "$id", value: "id")]) == UserCohort(identifier: Identifier(type: "$id", value: "id"), cohorts: [Cohort(id: 1), Cohort(id: 2)])
            expect(userCohorts[Identifier(type: "$id", value: "42")]).to(beNil())

            // filterBy
            expect(userCohorts.filterBy(user: User.builder().id("id").build()).rawCohorts) == [Cohort(id: 1), Cohort(id: 2)]
            expect(userCohorts.filterBy(user: User.builder().id("42").build()).rawCohorts) == []

            // toBuilder
            let cohorts2 = userCohorts.toBuilder()
                .put(cohort: UserCohort(
                    identifier: Identifier(type: "$deviceId", value: "device_id"),
                    cohorts: [Cohort(id: 4)])
                )
                .build()
            expect(cohorts2.rawCohorts.count) == 4
        }
    }
}