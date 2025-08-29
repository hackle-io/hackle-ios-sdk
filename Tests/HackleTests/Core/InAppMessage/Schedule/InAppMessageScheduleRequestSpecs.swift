import Foundation
import Nimble
import Quick

@testable import Hackle

class InAppMessageScheduleRequestSpecs: QuickSpec {
    override func spec() {
        it("delay") {
            let startedAt = Date(timeIntervalSince1970: 10)
            let deliverAt = Date(timeIntervalSince1970: 50)
            let requestedAt = Date(timeIntervalSince1970: 25)
            let request = InAppMessage.scheduleRequest(
                schedule: InAppMessage.schedule(
                    time: InAppMessageSchedule.Time(
                        startedAt: startedAt,
                        deliverAt: deliverAt
                    )
                ),
                requetedAt: requestedAt
            )

            expect(request.delay) == 25
        }
    }
}
