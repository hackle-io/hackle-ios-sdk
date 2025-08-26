import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageTriggerHandlerSpecs: QuickSpec {
    override func spec() {

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
            let inAppMessage = InAppMessage.create()
            let evaluation = InAppMessageEvaluation(isEligible: true, reason: DecisionReason.IN_APP_MESSAGE_TARGET)
            let event = UserEvents.track("test", timestamp: 42)
            let trigger = InAppMessageTrigger(inAppMessage: inAppMessage, evaluation: evaluation, event: event)

            let scheduleResponse = InAppMessageScheduleResponse.of(
                request: InAppMessageSchedule.create(trigger: trigger).toRequest(type: .triggered, requestedAt: Date(timeIntervalSince1970: 42)),
                code: .deliver
            )
            every(scheduleProcessor.processMock).returns(scheduleResponse)

            // when
            sut.handle(trigger: trigger)

            // then
            verify(exactly: 1) {
                scheduleProcessor.processMock
            }
            let request = scheduleProcessor.processMock.firstInvokation()
                .arguments
            expect(request.scheduleType) == .triggered
            expect(request.requestedAt) == Date(timeIntervalSince1970: 42)
        }
    }
}
