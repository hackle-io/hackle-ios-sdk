import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageDelayManagerSpecs: QuickSpec {
    override func spec() {

        var scheduler: MockInAppMessageDelayScheduler!
        var sut: DefaultInAppMessageDelayManager!

        beforeEach {
            scheduler = MockInAppMessageDelayScheduler()
            sut = DefaultInAppMessageDelayManager(scheduler: scheduler)
        }

        it("flow") {
            let request1 = InAppMessage.schedule(dispatchId: "1").toRequest(
                type: .triggered,
                requestedAt: Date(timeIntervalSince1970: 42)
            )
            let task1 = task(request: request1)
            every(scheduler.scheduleMock).returns(task1)

            // delay
            let delay1 = try sut.delay(request: request1)
            expect(delay1.schedule).to(beIdenticalTo(request1.schedule))

            // re-delay
            let _ = try sut.delay(request: request1)

            // delay 2
            let request2 = InAppMessage.schedule(dispatchId: "2").toRequest(
                type: .triggered,
                requestedAt: Date(timeIntervalSince1970: 42)
            )
            let task2 = task(request: request2)
            every(scheduler.scheduleMock).returns(task2)

            let delay2 = try sut.delay(request: request2)
            expect(delay2.schedule).to(beIdenticalTo(request2.schedule))

            // delete 1
            let deletedDelay1 = sut.delete(request: request1)
            expect(deletedDelay1?.schedule.dispatchId) == "1"

            // cancelAll
            expect(task2.cancelled) == false
            let cancelled = sut.cancelAll()
            expect(task2.cancelled) == true
            expect(cancelled.count) == 1
            expect(cancelled[0].schedule.dispatchId) == "2"
        }

        func task(request: InAppMessageScheduleRequest) -> InAppMessageDelayTaskStub {
            return InAppMessageDelayTaskStub(
                delay: InAppMessageDelay.from(request: request)
            )
        }
    }

    class InAppMessageDelayTaskStub: InAppMessageDelayTask {

        var cancelled = false
        let delay: InAppMessageDelay

        init(delay: InAppMessageDelay) {
            self.delay = delay
        }

        func cancel() {
            cancelled = true
        }
    }
}
