import Foundation

protocol InAppMessageTriggerDeterminer {
    func determine(event: UserEvent) throws -> InAppMessageTrigger?
}

class AbstractInAppMessageTriggerDeterminer: InAppMessageTriggerDeterminer {

    let eventMatcher: InAppMessageTriggerEventMatcher

    init(eventMatcher: InAppMessageTriggerEventMatcher) {
        self.eventMatcher = eventMatcher
    }

    func workspace(user: HackleUser) -> WorkspaceConfig? {
        fatalError("abstract method: workspace(user:)")
    }

    func evaluate(workspace: WorkspaceConfig, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
        fatalError("abstract method: evaluate(workspace:inAppMessage:event:)")
    }

    final func determine(event: UserEvent) throws -> InAppMessageTrigger? {
        guard let trackEvent = event as? UserEvents.Track else {
            return nil
        }

        guard let workspace = workspace(user: trackEvent.user) else {
            return nil
        }

        for inAppMessage in workspace.inAppMessages {
            let matches = try eventMatcher.matches(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent)
            if !matches {
                continue
            }

            let evaluation = try evaluate(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent)
            if evaluation.eligibilityResult.isEligible {
                return InAppMessageTrigger(inAppMessage: inAppMessage, reason: evaluation.eligibilityResult.reason, event: trackEvent)
            }
        }
        return nil
    }
}
