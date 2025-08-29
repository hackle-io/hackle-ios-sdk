import Foundation

protocol InAppMessageTriggerDeterminer {
    func determine(event: UserEvent) throws -> InAppMessageTrigger?
}

class DefaultInAppMessageTriggerDeterminer: InAppMessageTriggerDeterminer {

    private let workspaceFetcher: WorkspaceFetcher
    private let eventMatcher: InAppMessageTriggerEventMatcher
    private let evaluateProcessor: InAppMessageEvaluateProcessor

    init(workspaceFetcher: WorkspaceFetcher, eventMatcher: InAppMessageTriggerEventMatcher, evaluateProcessor: InAppMessageEvaluateProcessor) {
        self.workspaceFetcher = workspaceFetcher
        self.eventMatcher = eventMatcher
        self.evaluateProcessor = evaluateProcessor
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

            let evaluation = try evaluate(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent)
            if evaluation.isEligible {
                return InAppMessageTrigger(inAppMessage: inAppMessage, reason: evaluation.reason, event: trackEvent)
            }
        }
        return nil
    }

    private func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
        let request = InAppMessageEligibilityRequest(workspace: workspace, user: event.user, inAppMessage: inAppMessage, timestamp: event.timestamp)
        return try evaluateProcessor.process(type: .trigger, request: request)
    }
}
