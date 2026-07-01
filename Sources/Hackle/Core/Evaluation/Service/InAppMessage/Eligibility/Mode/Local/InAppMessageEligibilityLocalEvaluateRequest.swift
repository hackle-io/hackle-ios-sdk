import Foundation

final class InAppMessageEligibilityLocalEvaluateRequest: LocalEvaluateRequest, InAppMessageEligibilityEvaluateRequest, CustomStringConvertible {

    let workspace: WorkspaceConfig
    let inAppMessage: InAppMessage
    let user: HackleUser
    let scope: InAppMessageEvaluateScope
    let timestamp: Date

    var entity: ConfigEntity { inAppMessage }
    var record: Bool { true }

    private init(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessage,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        timestamp: Date
    ) {
        self.workspace = workspace
        self.inAppMessage = inAppMessage
        self.user = user
        self.scope = scope
        self.timestamp = timestamp
    }

    var description: String {
        "InAppMessageEligibilityEvaluateRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }

    static func of(
        workspace: WorkspaceConfig,
        inAppMessage: InAppMessage,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        timestamp: Date
    ) -> InAppMessageEligibilityLocalEvaluateRequest {
        InAppMessageEligibilityLocalEvaluateRequest(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            scope: scope,
            timestamp: timestamp
        )
    }
}
