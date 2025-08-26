import Foundation

protocol InAppMessageTriggerDeterminer {
    func determine(event: UserEvent) throws -> InAppMessageTrigger?
}

class DefaultInAppMessageTriggerDeterminer: InAppMessageTriggerDeterminer {

    private let workspaceFetcher: WorkspaceFetcher
    private let eventMatcher: InAppMessageTriggerEventMatcher
    private let evaluator: InAppMessageEvaluator

    init(workspaceFetcher: WorkspaceFetcher, eventMatcher: InAppMessageTriggerEventMatcher, evaluator: InAppMessageEvaluator) {
        self.workspaceFetcher = workspaceFetcher
        self.eventMatcher = eventMatcher
        self.evaluator = evaluator
    }

    func determine(event: UserEvent) throws -> InAppMessageTrigger? {
        guard let trackEvent = event as? UserEvents.Track else {
            return nil
        }

        guard let workspace = workspaceFetcher.fetch() else {
            return nil
        }

        for inAppMessage in workspace.inAppMessages {
            let matches = try eventMatcher.matches(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent)
            if !matches {
                continue
            }

            let evaluation = try evaluator.evaluate(workspace: workspace, inAppMessage: inAppMessage, user: event.user, timestamp: event.timestamp)
            if evaluation.isEligible {
                return InAppMessageTrigger(inAppMessage: inAppMessage, evaluation: evaluation, event: trackEvent)
            }
        }
        return nil
    }
}
