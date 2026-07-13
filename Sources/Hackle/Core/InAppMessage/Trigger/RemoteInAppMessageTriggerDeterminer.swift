import Foundation

class RemoteInAppMessageTriggerDeterminer: AbstractInAppMessageTriggerDeterminer {

    private let workspaceManager: WorkspaceEvaluationManager
    private let evaluateProcessor: EvaluateProcessor

    init(
        eventMatcher: InAppMessageTriggerEventMatcher,
        workspaceManager: WorkspaceEvaluationManager,
        evaluateProcessor: EvaluateProcessor
    ) {
        self.workspaceManager = workspaceManager
        self.evaluateProcessor = evaluateProcessor
        super.init(eventMatcher: eventMatcher)
    }

    override func workspace(user: HackleUser) -> Workspace? {
        let workspace: WorkspaceEvaluation? = workspaceManager.workspace(user: user)
        return workspace
    }

    override func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
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
