import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageTriggerProcessorSpecs: QuickSpec {
    override func spec() {

        var determiner: MockInAppMessageTriggerDeterminer!
        var handler: MockInAppMessageTriggerHandler!
        var sut: DefaultInAppMessageTriggerProcessor!

        beforeEach {
            determiner = MockInAppMessageTriggerDeterminer()
            handler = MockInAppMessageTriggerHandler()
            sut = DefaultInAppMessageTriggerProcessor(determiner: determiner, handler: handler)
        }

        it("when trigger not determiend the do not handle") {
            // given
            every(determiner.determineMock).returns(nil)
            let event = UserEvents.track("test")

            // when
            sut.process(event: event)

            // then
            verify(exactly: 0) {
                handler.handleMock
            }
        }

        it("when trigger determined then handle trigger") {
            // given
            let inAppMessage = InAppMessage.create()
            let event = UserEvents.track("test", timestamp: 42)
            let trigger = InAppMessageTrigger(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_TARGET, event: event)
            every(determiner.determineMock).returns(trigger)

            // when
            sut.process(event: event)

            // then
            verify(exactly: 1) {
                handler.handleMock
            }
        }

        it("when error occurs during handle trigger then ignore") {
            // given
            let inAppMessage = InAppMessage.create()
            let event = UserEvents.track("test", timestamp: 42)
            let trigger = InAppMessageTrigger(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_TARGET, event: event)
            every(determiner.determineMock).returns(trigger)

            every(handler.handleMock).answers { _ in
                throw HackleError.error("fail")
            }

            sut.process(event: event)
        }
    }
}
