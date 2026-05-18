import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageDeliverRequestSpecs: QuickSpec {
    override class func spec() {
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

        it("trigger event is taken from schedule.eventBasedContext.event") {
            let event = Event.builder("purchase").value(19.99).property("plan", "premium").build()
            let schedule = InAppMessage.schedule(
                eventBasedContext: InAppMessageSchedule.EventBasedContext(insertId: "ins", event: event)
            )
            let scheduleRequest = InAppMessage.scheduleRequest(schedule: schedule)

            let deliverRequest = InAppMessageDeliverRequest.of(request: scheduleRequest)

            expect(deliverRequest.triggerEvent.key) == "purchase"
            expect(deliverRequest.triggerEvent.value) == 19.99
            expect(deliverRequest.triggerEvent.properties?["plan"] as? String) == "premium"
        }
    }
}
