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

        it("handle은 triggered schedule 요청을 FIFO 큐에 제출한다") {
            // given
            let inAppMessage = InAppMessageEntity.create()
            let event = UserEvents.track("test", timestamp: 42)
            let trigger = InAppMessageTrigger(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_TARGET, event: event)

            // when
            try sut.handle(trigger: trigger)

            // then
            expect(scheduleProcessor.processAsyncMock.invokations().count) == 1
            let request = scheduleProcessor.processAsyncMock.firstInvokation().arguments
            expect(request.scheduleType) == .triggered
            expect(request.requestedAt) == Date(timeIntervalSince1970: 42)
        }

        it("연속 handle의 제출 순서가 보존된다") {
            // given
            let inAppMessage = InAppMessageEntity.create()
            let trigger1 = InAppMessageTrigger(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_TARGET, event: UserEvents.track("e1", timestamp: 1))
            let trigger2 = InAppMessageTrigger(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_TARGET, event: UserEvents.track("e2", timestamp: 2))

            // when
            try sut.handle(trigger: trigger1)
            try sut.handle(trigger: trigger2)

            // then
            let requestedAts = scheduleProcessor.processAsyncMock.invokations().map { $0.arguments.requestedAt }
            expect(requestedAts) == [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2)]
        }
    }
}
