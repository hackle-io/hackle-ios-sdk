import Foundation

extension EvaluateProcessor {

    // MARK: - LOCAL

    func eligibility(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessageConfig,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        timestamp: Date
    ) throws -> InAppMessageEligibilityEvaluateResponse {
        let request = InAppMessageEligibilityLocalEvaluateRequest.of(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            scope: scope,
            platformType: .ios,
            timestamp: timestamp
        )
        return try self.inAppMessage(request)
    }

    func layout(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessageConfig,
        user: HackleUser,
        scope: InAppMessageEvaluateScope
    ) throws -> InAppMessageLayoutEvaluateResponse {
        let request = InAppMessageLayoutLocalEvaluateRequest.of(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            scope: scope
        )
        return try self.inAppMessage(request)
    }

    // MARK: - REMOTE

    func eligibility(
        workspace: WorkspaceEvaluation,
        inAppMessage: InAppMessageEligibilityRemoteEvaluateResult,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        timestamp: Date,
        record: Bool = true
    ) throws -> InAppMessageEligibilityEvaluateResponse {
        let request = InAppMessageEligibilityRemoteEvaluateRequest.of(
            workspace: workspace,
            entity: inAppMessage,
            user: user,
            scope: scope,
            platformType: .ios,
            timestamp: timestamp,
            record: record
        )
        return try self.inAppMessage(request)
    }

    func layout(
        workspace: WorkspaceEvaluation,
        inAppMessage: InAppMessageEligibilityRemoteEvaluateResult,
        user: HackleUser,
        scope: InAppMessageEvaluateScope
    ) throws -> InAppMessageLayoutEvaluateResponse {
        let request = InAppMessageLayoutRemoteEvaluateRequest.of(
            workspace: workspace,
            entity: inAppMessage.layout,
            user: user,
            scope: scope
        )
        return try self.inAppMessage(request)
    }
}
