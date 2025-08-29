import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultEvaluationEventRecorderSpecs: QuickSpec {
    override func spec() {

        var eventFactory: MockUserEventFactory!
        var eventProcessor: MockUserEventProcessor!
        var sut: DefaultEvaluationEventRecorder!

        beforeEach {
            eventFactory = MockUserEventFactory()
            eventProcessor = MockUserEventProcessor()
            sut = DefaultEvaluationEventRecorder(eventFactory: eventFactory, eventProcessor: eventProcessor)
        }

        it("record") {
            // given
            let request = InAppMessage.layoutRequest()
            let evaluation = InAppMessage.layoutEvaluation()

            let events = [UserEvents.track("test"), UserEvents.track("test")]
            eventFactory.events = events

            // when
            sut.record(request: request, evaluation: evaluation)

            // then
            verify(exactly: 2) {
                eventProcessor.processMock
            }
        }
    }
}
