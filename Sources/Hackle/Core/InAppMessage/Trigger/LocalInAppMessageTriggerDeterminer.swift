import Foundation

final class LocalInAppMessageTriggerDeterminer: InAppMessageTriggerDeterminer {
    let eventMatcher: InAppMessageTriggerEventMatcher

    private let workspaceFetcher: WorkspaceConfigFetcher
    private let evaluateProcessor: EvaluateProcessor

    init(
        eventMatcher: InAppMessageTriggerEventMatcher,
        workspaceFetcher: WorkspaceConfigFetcher,
        evaluateProcessor: EvaluateProcessor
    ) {
        self.eventMatcher = eventMatcher
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
    }

    func workspace(user: HackleUser) -> Workspace? {
        workspaceFetcher.workspace(user: user)
    }

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
        guard let workspaceConfig = workspace as? WorkspaceConfig, let inAppMessageConfig = inAppMessage as? InAppMessageConfig else {
            throw HackleError.error("Unsupported workspace type for local trigger (key=\(inAppMessage.key))")
        }
        let response = try evaluateProcessor.eligibility(
            workspace: workspaceConfig,
            inAppMessage: inAppMessageConfig,
            user: event.user,
            scope: .trigger,
            timestamp: event.timestamp
        )
        return response.eligibilityEvaluation
    }
}
