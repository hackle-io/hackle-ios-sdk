import Foundation
import Quick
import Nimble
@testable import Hackle

class TriggeredInAppMessageSchedulerSpecs: QuickSpec {
    override func spec() {

        var deliverProcessor: MockInAppMessageDeliverProcessor!
        var delayManager: MockInAppMessageDelayManager!
        var sut: TriggeredInAppMessageScheduler!

        beforeEach {
            deliverProcessor = MockInAppMessageDeliverProcessor()
            delayManager = MockInAppMessageDelayManager()
            sut = TriggeredInAppMessageScheduler(
                deliverProcessor: deliverProcessor,
                delayManager: delayManager
            )
        }

        it("supports") {
            expect(sut.support(scheduleType: .triggered)) == true
            expect(sut.support(scheduleType: .delayed)) == false
        }

        describe("deliver") {
            it("process deliver") {
                // given
                let request = InAppMessage.scheduleRequest()

                let deliverResponse = InAppMessage.deliverResponse()
                every(deliverProcessor.processMock).returns(deliverResponse)

                // when
                let actual = try sut.schedule(action: .deliver, request: request)

                // then
                expect(actual.code) == .deliver
                expect(actual.deliverResponse).to(beIdenticalTo(deliverResponse))
            }
        }

        describe("delay") {
            it("registerAndDelay") {
                let request = InAppMessage.scheduleRequest()

                let delay = InAppMessageDelay.from(request: request)
                every(delayManager.registerAndDelayMock).returns(delay)

                // when
                let actual = try sut.schedule(action: .delay, request: request)

                // then
                expect(actual.code) == .delay
                expect(actual.delay).to(beIdenticalTo(delay))
            }
        }

        describe("ignore") {
            it("do nothing") {
                // given
                let request = InAppMessage.scheduleRequest()

                // when
                let actual = try sut.schedule(action: .ignore, request: request)

                // then
                expect(actual.code) == .ignore
            }
        }
    }
}
