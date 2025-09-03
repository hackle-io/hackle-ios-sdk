import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageDeliverRequestSpecs: QuickSpec {
    override func spec() {
        it("create") {
            let schedule = InAppMessage.schedule(
                dispatchId: "111",
                inAppMessageKey: 42,
                eventBasedContext: InAppMessageSchedule.EventBasedContext(insertId: "insert_id", event: Event.builder("test").build())
            )
            let scheduleRequest = InAppMessage.scheduleRequest(
                schedule: schedule
            )

            let deliverRequest = InAppMessageDeliverRequest.of(request: scheduleRequest)
            expect(deliverRequest.dispatchId) == "111"
            expect(deliverRequest.inAppMessageKey) == 42
            expect(deliverRequest.properties["$trigger_event_insert_id"] as? String) == "insert_id"
        }
    }
}
