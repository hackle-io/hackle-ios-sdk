import Foundation

final class InAppMessageLayoutLocalEvaluateRequest: LocalEvaluateRequest, InAppMessageLayoutEvaluateRequest, CustomStringConvertible {

    let workspaceConfig: WorkspaceConfig
    let inAppMessageConfig: InAppMessageConfig
    let user: HackleUser
    let record: Bool
    let scope: InAppMessageEvaluateScope

    var workspace: Workspace { workspaceConfig }
    var entity: Entity { inAppMessageConfig }
    var inAppMessage: InAppMessage { inAppMessageConfig }

    private init(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessageConfig,
        user: HackleUser,
        record: Bool,
        scope: InAppMessageEvaluateScope
    ) {
        self.workspaceConfig = workspace
        self.inAppMessageConfig = inAppMessage
        self.user = user
        self.record = record
        self.scope = scope
    }

    var description: String {
        "InAppMessageLayoutLocalEvaluateRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }

    static func of(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessageConfig,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        record: Bool = true
    ) -> InAppMessageLayoutLocalEvaluateRequest {
        InAppMessageLayoutLocalEvaluateRequest(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            record: record,
            scope: scope
        )
    }

    static func of(request: InAppMessageEligibilityLocalEvaluateRequest) -> InAppMessageLayoutLocalEvaluateRequest {
        InAppMessageLayoutLocalEvaluateRequest(
            workspace: request.workspaceConfig,
            inAppMessage: request.inAppMessageConfig,
            user: request.user,
            record: request.record,
            scope: request.scope
        )
    }
}
