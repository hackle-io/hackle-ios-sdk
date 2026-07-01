import Foundation

final class InAppMessageLayoutLocalEvaluateRequest: LocalEvaluateRequest, InAppMessageLayoutEvaluateRequest, CustomStringConvertible {

    let workspace: WorkspaceConfig
    let inAppMessage: InAppMessage
    let user: HackleUser
    let record: Bool
    let scope: InAppMessageEvaluateScope

    var entity: ConfigEntity { inAppMessage }

    private init(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessage,
        user: HackleUser,
        record: Bool,
        scope: InAppMessageEvaluateScope
    ) {
        self.workspace = workspace
        self.inAppMessage = inAppMessage
        self.user = user
        self.record = record
        self.scope = scope
    }

    var description: String {
        "InAppMessageLayoutLocalEvaluateRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }

    static func of(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessage,
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
            workspace: request.workspace,
            inAppMessage: request.inAppMessage,
            user: request.user,
            record: request.record,
            scope: request.scope
        )
    }
}
