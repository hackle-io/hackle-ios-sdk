import Foundation

// android trigger/LocalInAppMessageTriggerDeterminer.kt 이식.
// AbstractInAppMessageTriggerDeterminer의 LOCAL 특수화 (WorkspaceConfigFetcher 기반 평가).
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
        let request = InAppMessageEligibilityLocalEvaluateRequest.of(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: event.user,
            scope: .trigger,
            platformType: .ios,
            timestamp: event.timestamp
        )
        return try evaluateProcessor.process(type: .trigger, request: request)
    }
}
