import Foundation
import Nimble
import Quick
@testable import Hackle

class LocalUserContextSpecs: QuickSpec {
    override class func spec() {

        func cohorts(_ entries: (Identifier, [Cohort])...) -> UserCohorts {
            let builder = UserCohorts.builder()
            for (identifier, cohorts) in entries {
                _ = builder.put(cohort: UserCohort(identifier: identifier, cohorts: cohorts))
            }
            return builder.build()
        }

        describe("update(cohorts:) - merge 의미론 (android LocalUserContext.kt 파리티)") {

            let id = Identifier(type: "$id", value: "id")
            let userId = Identifier(type: "$userId", value: "user_id")
            let user = User.builder().id("id").userId("user_id").build()

            it("같은 identifier의 코호트는 새 응답으로 교체된다 (new-wins)") {
                let context = LocalUserContext.of(
                    user: user,
                    cohorts: cohorts((id, [Cohort(id: 1)])),
                    targetEvents: UserTargetEvents.builder().build()
                )

                let updated = context.update(cohorts: cohorts((id, [Cohort(id: 2)])))

                expect(updated.cohorts[id]?.cohorts) == [Cohort(id: 2)]
            }

            it("응답에서 생략된 identifier의 기존 코호트는 유지된다 (replace가 아닌 merge)") {
                let context = LocalUserContext.of(
                    user: user,
                    cohorts: cohorts((id, [Cohort(id: 1)]), (userId, [Cohort(id: 2)])),
                    targetEvents: UserTargetEvents.builder().build()
                )

                // 서버 응답에 $id 항목만 존재 - $userId 항목은 생략됨
                let updated = context.update(cohorts: cohorts((id, [Cohort(id: 3)])))

                expect(updated.cohorts[id]?.cohorts) == [Cohort(id: 3)]
                expect(updated.cohorts[userId]?.cohorts) == [Cohort(id: 2)]
            }

            it("현재 user의 identifier가 아닌 응답 코호트는 필터링된다") {
                let context = LocalUserContext.of(
                    user: user,
                    cohorts: cohorts((id, [Cohort(id: 1)])),
                    targetEvents: UserTargetEvents.builder().build()
                )

                let other = Identifier(type: "$userId", value: "other_user")
                let updated = context.update(cohorts: cohorts((other, [Cohort(id: 9)])))

                expect(updated.cohorts[other]).to(beNil())
                expect(updated.cohorts[id]?.cohorts) == [Cohort(id: 1)]
            }
        }
    }
}
