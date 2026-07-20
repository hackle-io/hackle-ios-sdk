import Foundation

final class RemoteInAppMessageTriggerDeterminer: InAppMessageTriggerDeterminer {
    let eventMatcher: InAppMessageTriggerEventMatcher
    
    private let workspaceManager: WorkspaceEvaluationManager
    private let evaluateProcessor: EvaluateProcessor

    init(
        eventMatcher: InAppMessageTriggerEventMatcher,
        workspaceManager: WorkspaceEvaluationManager,
        evaluateProcessor: EvaluateProcessor
    ) {
        self.eventMatcher = eventMatcher
        self.workspaceManager = workspaceManager
        self.evaluateProcessor = evaluateProcessor
    }

    func workspace(user: HackleUser) -> Workspace? {
        let workspace: WorkspaceEvaluation? = workspaceManager.workspace(user: user)
        return workspace
    }

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
        guard let workspaceEvaluation = workspace as? WorkspaceEvaluation,
              let result = inAppMessage as? InAppMessageEligibilityRemoteEvaluateResult else {
            throw HackleError.error("Unsupported workspace type for remote trigger (key=\(inAppMessage.key))")
        }
        let response = try evaluateProcessor.eligibility(
            workspace: workspaceEvaluation,
            inAppMessage: result,
            user: event.user,
            scope: .trigger,
            timestamp: event.timestamp
        )
        return response.eligibilityEvaluation
    }
}
