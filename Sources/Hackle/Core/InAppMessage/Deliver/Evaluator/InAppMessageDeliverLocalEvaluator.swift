import Foundation

class InAppMessageDeliverLocalEvaluator: InAppMessageDeliverEvaluator {

    private let workspaceFetcher: WorkspaceConfigFetcher
    private let layoutResolver: InAppMessageLayoutResolver
    private let evaluateProcessor: InAppMessageEvaluateProcessor

    init(
        workspaceFetcher: WorkspaceConfigFetcher,
        layoutResolver: InAppMessageLayoutResolver,
        evaluateProcessor: InAppMessageEvaluateProcessor
    ) {
        self.workspaceFetcher = workspaceFetcher
        self.layoutResolver = layoutResolver
        self.evaluateProcessor = evaluateProcessor
    }

    func evaluate(request: InAppMessageDeliverRequest, user: HackleUser) throws -> InAppMessageDeliverEvaluateResponse {

        // check Workspace
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return InAppMessageDeliverEvaluateResponse.ineligible(code: .workspaceNotFound)
        }

        // check InAppMessage
        guard let inAppMessage = workspace.getInAppMessageOrNil(inAppMessageKey: request.inAppMessageKey) else {
            return InAppMessageDeliverEvaluateResponse.ineligible(code: .inAppMessageNotFound)
        }

        // resolve layout
        let layout = try layoutResolver.resolve(workspace: workspace, inAppMessage: inAppMessage, user: user)

        // check Evaluation (re-evaluate + dedup)
        let eligibilityRequest = InAppMessageEligibilityLocalEvaluateRequest.of(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            scope: .deliver,
            platformType: .ios,
            timestamp: request.requestedAt
        )
        let eligibility = try evaluateProcessor.process(type: .deliver, request: eligibilityRequest)

        let evaluation = InAppMessageDeliverEvaluation(eligibility: eligibility, layout: layout)
        return InAppMessageDeliverEvaluateResponse.of(evaluation: evaluation)
    }
}
