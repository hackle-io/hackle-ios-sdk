import Foundation

protocol EvaluationEventRecorder {
    func record(request: EvaluatorRequest, evaluation: EvaluatorEvaluation)
}

class DefaultEvaluationEventRecorder: EvaluationEventRecorder {

    private let eventFactory: UserEventFactory
    private let eventProcessor: UserEventProcessor

    init(eventFactory: UserEventFactory, eventProcessor: UserEventProcessor) {
        self.eventFactory = eventFactory
        self.eventProcessor = eventProcessor
    }

    func record(request: EvaluatorRequest, evaluation: EvaluatorEvaluation) {
        let events = eventFactory.create(request: request, evaluation: evaluation)
        eventProcessor.process(events: events)
    }
}
