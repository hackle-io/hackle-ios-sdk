import Foundation

class InAppMessageDeliverLocalEvaluator: InAppMessageDeliverEvaluator {

    private let workspaceFetcher: WorkspaceConfigFetcher
    private let evaluateProcessor: EvaluateProcessor

    init(workspaceFetcher: WorkspaceConfigFetcher, evaluateProcessor: EvaluateProcessor) {
        self.workspaceFetcher = workspaceFetcher
        self.evaluateProcessor = evaluateProcessor
    }

    func evaluate(request: InAppMessageDeliverRequest, user: HackleUser) throws -> InAppMessageDeliverEvaluateResponse {

        // check Workspace
        guard let workspace = workspaceFetcher.workspace(user: user) else {
            return InAppMessageDeliverEvaluateResponse.ineligible(code: .workspaceNotFound)
        }

        // check InAppMessage
        guard let inAppMessage = workspace.getInAppMessageConfigOrNil(inAppMessageKey: request.inAppMessageKey) else {
            return InAppMessageDeliverEvaluateResponse.ineligible(code: .inAppMessageNotFound)
        }

        // resolve layout
        let layout = try evaluateProcessor.layout(workspace: workspace, inAppMessage: inAppMessage, user: user, scope: .deliver)

        // check Evaluation (re-evaluate + dedup)
        let eligibility = try evaluateProcessor.eligibility(workspace: workspace, inAppMessage: inAppMessage, user: user, scope: .deliver, timestamp: request.requestedAt)

        let evaluation = InAppMessageDeliverEvaluation(eligibility: eligibility.eligibilityEvaluation, layout: layout)
        return InAppMessageDeliverEvaluateResponse.of(evaluation: evaluation)
    }
}
