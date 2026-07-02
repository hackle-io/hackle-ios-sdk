import Foundation

final class InAppMessageEligibilityLocalEvaluateRequest: LocalEvaluateRequest, InAppMessageEligibilityEvaluateRequest, CustomStringConvertible {

    let workspace: Workspace
    let inAppMessage: InAppMessage
    let user: HackleUser
    let record: Bool
    let scope: InAppMessageEvaluateScope
    let platformType: InAppMessage.PlatformType
    let timestamp: Date

    var entity: Entity { inAppMessage }

    private init(
        workspace: Workspace,
        inAppMessage: InAppMessage,
        user: HackleUser,
        record: Bool,
        scope: InAppMessageEvaluateScope,
        platformType: InAppMessage.PlatformType,
        timestamp: Date
    ) {
        self.workspace = workspace
        self.inAppMessage = inAppMessage
        self.user = user
        self.record = record
        self.scope = scope
        self.platformType = platformType
        self.timestamp = timestamp
    }

    var description: String {
        "InAppMessageEligibilityEvaluateRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }

    static func of(
        workspace: Workspace,
        inAppMessage: InAppMessage,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        platformType: InAppMessage.PlatformType,
        timestamp: Date,
        record: Bool = true
    ) -> InAppMessageEligibilityLocalEvaluateRequest {
        InAppMessageEligibilityLocalEvaluateRequest(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            record: record,
            scope: scope,
            platformType: platformType,
            timestamp: timestamp
        )
    }
}
