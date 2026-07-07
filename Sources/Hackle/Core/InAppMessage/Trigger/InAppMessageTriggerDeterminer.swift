import Foundation

protocol InAppMessageTriggerDeterminer {
    func determine(event: UserEvent) throws -> InAppMessageTrigger?
}

// android AbstractInAppMessageTriggerDeterminer<WORKSPACE, MESSAGE> 이식.
// iOS는 InAppMessage(final class)·WorkspaceConfig(protocol existential) 특성상 제네릭 특수화가
// 불가하여(결정 B) base Workspace/InAppMessage로 동작하는 비제네릭 template method로 구현.
class AbstractInAppMessageTriggerDeterminer: InAppMessageTriggerDeterminer {

    let eventMatcher: InAppMessageTriggerEventMatcher

    init(eventMatcher: InAppMessageTriggerEventMatcher) {
        self.eventMatcher = eventMatcher
    }

    func workspace(user: HackleUser) -> Workspace? {
        fatalError("abstract method: workspace(user:)")
    }

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
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
