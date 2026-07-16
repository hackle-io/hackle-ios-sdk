import Foundation
import Nimble
import Quick

@testable import Hackle

class DelayedInAppMessageSchedulerSpecs: AsyncSpec {
    override class func spec() {

        var deliverProcessor: MockInAppMessageDeliverProcessor!
        var delayManager: MockInAppMessageDelayManager!
        var sut: DelayedInAppMessageScheduler!

        beforeEach {
            deliverProcessor = MockInAppMessageDeliverProcessor()
            delayManager = MockInAppMessageDelayManager()
            sut = DelayedInAppMessageScheduler(
                deliverProcessor: deliverProcessor,
                delayManager: delayManager
            )
        }

        it("supports") {
            expect(sut.support(scheduleType: .triggered)) == false
            expect(sut.support(scheduleType: .delayed)) == true
        }

        describe("deliver") {
            it("when delay not found then throws") {
                let request = InAppMessageEntity.scheduleRequest()
                every(delayManager.deleteMock).returns(nil)

                await expect {
                    try await sut.schedule(action: .deliver, request: request)
                }
                    .to(throwError())
            }

            it("deliver") {
                // given
                let request = InAppMessageEntity.scheduleRequest()

                let delay = InAppMessageDelay.from(request: request)
                every(delayManager.deleteMock).returns(delay)

                let deliverResponse = InAppMessageEntity.deliverResponse()
                every(deliverProcessor.processMock).returns(deliverResponse)

                // when
                let actual = try await sut.schedule(
                    action: .deliver,
                    request: request
                )

                // then
                expect(actual.code) == .deliver
                expect(actual.deliverResponse).to(beIdenticalTo(deliverResponse))
            }
        }

        describe("delay") {
            it("delay") {
                // given
                let request = InAppMessageEntity.scheduleRequest()

                let delay = InAppMessageDelay.from(request: request)
                every(delayManager.delayMock).returns(delay)

                // when
                let actual = try await sut.schedule(action: .delay, request: request)

                // then
                expect(actual.code) == .delay
                expect(actual.delay).to(beIdenticalTo(delay))
            }
        }

        describe("ignore") {
            it("delete delay") {
                // given
                let request = InAppMessageEntity.scheduleRequest()

                let delay = InAppMessageDelay.from(request: request)
                every(delayManager.deleteMock).returns(delay)

                // when
                let actual = try await sut.schedule(action: .ignore, request: request)

                // then
                expect(actual.code) == .ignore
                expect(actual.delay).to(beIdenticalTo(delay))
            }
        }
    }
}
