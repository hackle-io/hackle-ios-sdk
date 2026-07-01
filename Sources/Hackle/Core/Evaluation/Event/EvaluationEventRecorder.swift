import Foundation

class EvaluationEventRecorder {

    private let eventFactory: EvaluationEventFactory
    private let eventProcessor: UserEventProcessor

    init(eventFactory: EvaluationEventFactory, eventProcessor: UserEventProcessor) {
        self.eventFactory = eventFactory
        self.eventProcessor = eventProcessor
    }

    func record(response: EvaluateResponse) {
        let events = eventFactory.create(response: response)
        eventProcessor.process(events: events)
    }
}
