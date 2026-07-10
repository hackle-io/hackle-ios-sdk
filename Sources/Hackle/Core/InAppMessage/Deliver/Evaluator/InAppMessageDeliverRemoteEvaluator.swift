import Foundation

class InAppMessageDeliverRemoteEvaluator: InAppMessageDeliverEvaluator {

    private let workspaceManager: WorkspaceEvaluationManager
    private let evaluateProcessor: EvaluateProcessor

    init(workspaceManager: WorkspaceEvaluationManager, evaluateProcessor: EvaluateProcessor) {
        self.workspaceManager = workspaceManager
        self.evaluateProcessor = evaluateProcessor
    }

    func evaluate(request: InAppMessageDeliverRequest, user: HackleUser) async throws -> InAppMessageDeliverEvaluateResponse {
        guard let workspace: WorkspaceEvaluation = workspaceManager.workspace(user: user) else {
            return InAppMessageDeliverEvaluateResponse.ineligible(code: .workspaceNotFound)
        }
        guard let inAppMessage = workspace.getInAppMessageResultOrNil(inAppMessageKey: request.inAppMessageKey) else {
            return InAppMessageDeliverEvaluateResponse.ineligible(code: .inAppMessageNotFound)
        }
        let resolvedWorkspace = try await resolveWorkspaceEvaluation(request: request, workspace: workspace, inAppMessage: inAppMessage, user: user)
        return try evaluate(request: request, workspace: resolvedWorkspace, user: user)
    }

    // atDeliverTime이면 time + dedup 만 먼저 evaluate 해서 API 호출 최적화 (record: false)
    private func resolveWorkspaceEvaluation(
        request: InAppMessageDeliverRequest,
        workspace: WorkspaceEvaluation,
        inAppMessage: InAppMessageEligibilityRemoteEvaluateResult,
        user: HackleUser
    ) async throws -> WorkspaceEvaluation {
        guard inAppMessage.evaluateContext.atDeliverTime else {
            return workspace
        }
        let response = try eligibility(request: request, workspace: workspace, inAppMessage: inAppMessage, user: user, record: false)
        if !response.eligibilityEvaluation.eligibilityResult.isEligible {
            return workspace
        }
        return try await workspaceManager.evaluate(context: WorkspaceEvaluateContext.of(user: user), entities: [inAppMessage])
    }

    private func evaluate(
        request: InAppMessageDeliverRequest,
        workspace: WorkspaceEvaluation,
        user: HackleUser
    ) throws -> InAppMessageDeliverEvaluateResponse {
        guard let inAppMessage = workspace.getInAppMessageResultOrNil(inAppMessageKey: request.inAppMessageKey) else {
            return InAppMessageDeliverEvaluateResponse.ineligible(code: .inAppMessageNotFound)
        }
        let layout = try evaluateProcessor.layout(workspace: workspace, inAppMessage: inAppMessage, user: user, scope: .deliver)
        let eligibility = try eligibility(request: request, workspace: workspace, inAppMessage: inAppMessage, user: user, record: true)
        let evaluation = InAppMessageDeliverEvaluation(eligibility: eligibility.eligibilityEvaluation, layout: layout)
        return InAppMessageDeliverEvaluateResponse.of(evaluation: evaluation)
    }

    private func eligibility(
        request: InAppMessageDeliverRequest,
        workspace: WorkspaceEvaluation,
        inAppMessage: InAppMessageEligibilityRemoteEvaluateResult,
        user: HackleUser,
        record: Bool
    ) throws -> InAppMessageEligibilityEvaluateResponse {
        try evaluateProcessor.eligibility(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            scope: .deliver,
            timestamp: request.requestedAt,
            record: record
        )
    }
}
