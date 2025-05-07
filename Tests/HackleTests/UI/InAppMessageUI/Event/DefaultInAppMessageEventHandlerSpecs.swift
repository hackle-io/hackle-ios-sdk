import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultInAppMessageEventHandlerSpecs: QuickSpec {
    override func spec() {

        var clock: Clock!
        var eventTracker: MockInAppMessageEventTracker!
        var eventProcessor: MockInAppMessageEventProcessor!
        var processorFactory: InAppMessageEventProcessorFactory!
        var sut: DefaultInAppMessageEventHandler!

        beforeEach {
            clock = FixedClock(date: Date(timeIntervalSince1970: 42))
            eventTracker = MockInAppMessageEventTracker()
            eventProcessor = MockInAppMessageEventProcessor(true)
            processorFactory = InAppMessageEventProcessorFactory(processors: [eventProcessor])
            sut = DefaultInAppMessageEventHandler(
                clock: clock,
                eventTracker: eventTracker,
                processorFactory: processorFactory
            )
        }

        describe("handle") {
            it("track") {
                // given
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.impression

                // when
                sut.handle(view: view, event: event)

                // then
                verify(exactly: 1) {
                    eventTracker.trackMock
                }
            }

            it("when cannot found event processor then do not process") {
                // given
                eventProcessor.supportsReturns = false
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.impression

                // when
                sut.handle(view: view, event: event)

                // then
                verify(exactly: 0) {
                    eventProcessor.processMock
                }
            }

            it("process event") {
                // given
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.impression

                // when
                sut.handle(view: view, event: event)

                // then
                verify(exactly: 1) {
                    eventProcessor.processMock
                }
            }
        }
    }
}
