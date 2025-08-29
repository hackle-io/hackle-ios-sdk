import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageScheduleActionDeterminerSpecs: QuickSpec {
    override func spec() {
        var sut: DefaultInAppMessageScheduleActionDeterminer!

        beforeEach {
            sut = DefaultInAppMessageScheduleActionDeterminer()
        }

        it("determine") {
            expect(try sut.determine(request: request(delay: 1))) == .delay
            expect(try sut.determine(request: request(delay: 0))) == .deliver
            expect(try sut.determine(request: request(delay: -60))) == .deliver
            expect(try sut.determine(request: request(delay: -61))) == .ignore
        }

        func request(delay: TimeInterval) -> InAppMessageScheduleRequest {
            let startedAt = Date()
            let deliverAt = startedAt.addingTimeInterval(delay)
            return InAppMessage.scheduleRequest(
                schedule: InAppMessage.schedule(
                    time: InAppMessageSchedule.Time(
                        startedAt: startedAt,
                        deliverAt: deliverAt
                    )
                ),
                requetedAt: startedAt
            )
        }
    }
}
