import Foundation

protocol InAppMessageTriggerDeterminer {
    var eventMatcher: InAppMessageTriggerEventMatcher { get }
    
    func workspace(user: HackleUser) -> Workspace?
    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation
    func determine(event: UserEvent) throws -> InAppMessageTrigger?
}

extension InAppMessageTriggerDeterminer {
    func determine(event: UserEvent) throws -> InAppMessageTrigger? {
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
