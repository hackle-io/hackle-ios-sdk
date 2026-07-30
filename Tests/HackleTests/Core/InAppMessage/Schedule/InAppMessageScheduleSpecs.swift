import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageScheduleSpecs: QuickSpec {
    override class func spec() {
        it("time") {
            let startedAt = Date(timeIntervalSince1970: 10)
            let deliverAt = Date(timeIntervalSince1970: 50)
            let time = InAppMessageSchedule.Time(
                startedAt: startedAt,
                deliverAt: deliverAt
            )
            let actual = time.delay(at: Date(timeIntervalSince1970: 25))
            expect(actual) == 25
        }

        it("AFTER인데 afterCondition이 없으면 throw한다 (크래시 금지)") {
            let delay = InAppMessageEntity.EventTrigger.Delay(type: .after, afterCondition: nil)
            expect { try delay.deliverAt(startedAt: Date(timeIntervalSince1970: 42)) }.to(throwError())
        }

        it("AFTER에 afterCondition이 있으면 duration만큼 더한다") {
            let delay = InAppMessageEntity.EventTrigger.Delay(
                type: .after,
                afterCondition: InAppMessageEntity.EventTrigger.Delay.AfterCondition(duration: 60)
            )
            let actual = try delay.deliverAt(startedAt: Date(timeIntervalSince1970: 42))
            expect(actual) == Date(timeIntervalSince1970: 102)
        }
    }
}
