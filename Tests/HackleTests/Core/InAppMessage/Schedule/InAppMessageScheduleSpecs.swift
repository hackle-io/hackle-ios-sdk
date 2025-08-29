import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageScheduleSpecs: QuickSpec {
    override func spec() {
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
    }
}
