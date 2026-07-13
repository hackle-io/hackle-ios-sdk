import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageTriggerHandlerSpecs: QuickSpec {
    override class func spec() {

        var scheduleProcessor: MockInAppMessageScheduleProcessor!
        var sut: DefaultInAppMessageTriggerHandler!

        beforeEach {
            scheduleProcessor = MockInAppMessageScheduleProcessor()
            sut = DefaultInAppMessageTriggerHandler(
                scheduleProcessor: scheduleProcessor
            )
        }

        it("handle") {
            // given
            let inAppMessage = InAppMessageEntity.create()
            let event = UserEvents.track("test", timestamp: 42)
            let trigger = InAppMessageTrigger(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_TARGET, event: event)

            let scheduleResponse = InAppMessageScheduleResponse.of(
                request: InAppMessageSchedule.create(trigger: trigger).toRequest(type: .triggered, requestedAt: Date(timeIntervalSince1970: 42)),
                code: .deliver
            )
            every(scheduleProcessor.processMock).returns(scheduleResponse)

            // when
            sut.handle(trigger: trigger)

            // then — handle은 Task {}로 발사되므로 toEventually로 완료 대기
            expect(scheduleProcessor.processMock.invokations().count).toEventually(equal(1), timeout: .seconds(5))
            let request = scheduleProcessor.processMock.firstInvokation()
                .arguments
            expect(request.scheduleType) == .triggered
            expect(request.requestedAt) == Date(timeIntervalSince1970: 42)
        }
    }
}
