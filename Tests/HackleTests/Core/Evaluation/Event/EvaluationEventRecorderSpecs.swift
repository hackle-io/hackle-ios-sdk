//
//  EvaluationEventRecorderSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class EvaluationEventRecorderSpecs: QuickSpec {
    override class func spec() {

        it("record processes events created by the factory") {
            // given
            let events = [UserEvents.track("test"), UserEvents.track("test")]
            let eventFactory = StubEvaluationEventFactory(events: events)
            let eventProcessor = MockUserEventProcessor()
            let sut = EvaluationEventRecorder(eventFactory: eventFactory, eventProcessor: eventProcessor)

            // when
            sut.record(response: StubEvaluateResponse())

            // then
            verify(exactly: 2) {
                eventProcessor.processMock
            }
        }
    }

    class StubEvaluationEventFactory: EvaluationEventFactory {
        private let events: [UserEvent]

        init(events: [UserEvent]) {
            self.events = events
            super.init(clock: FixedClock(date: Date()))
        }

        override func create(response: EvaluateResponse) -> [UserEvent] {
            events
        }
    }
}
