import Foundation

class LocalInAppMessageTriggerDeterminer: AbstractInAppMessageTriggerDeterminer {

    private let workspaceFetcher: WorkspaceConfigFetcher
    private let evaluateProcessor: InAppMessageEvaluateProcessor

    init(
        eventMatcher: InAppMessageTriggerEventMatcher,
        workspaceFetcher: WorkspaceConfigFetcher,
        evaluateProcessor: InAppMessageEvaluateProcessor
    ) {
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
        super.init(eventMatcher: eventMatcher)
    }

    override func workspace(user: HackleUser) -> Workspace? {
        return workspaceFetcher.workspace(user: user)
    }

    override func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
        guard let inAppMessageConfig = inAppMessage as? InAppMessageConfig else {
            throw HackleError.error("InAppMessageConfig[\(inAppMessage.key)]")
        }
        let request = InAppMessageEligibilityLocalEvaluateRequest.of(
            workspace: workspace,
            inAppMessage: inAppMessageConfig,
            user: event.user,
            scope: .trigger,
            platformType: .ios,
            timestamp: event.timestamp
        )
        return try evaluateProcessor.process(type: .trigger, request: request)
    }
}
