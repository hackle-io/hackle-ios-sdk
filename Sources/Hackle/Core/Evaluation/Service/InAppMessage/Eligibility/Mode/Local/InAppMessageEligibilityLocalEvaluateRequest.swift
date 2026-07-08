import Foundation

final class InAppMessageEligibilityLocalEvaluateRequest: LocalEvaluateRequest, InAppMessageEligibilityEvaluateRequest, CustomStringConvertible {

    let workspace: Workspace
    let inAppMessageConfig: InAppMessageConfig
    let user: HackleUser
    let record: Bool
    let scope: InAppMessageEvaluateScope
    let platformType: PlatformType
    let timestamp: Date

    var entity: Entity { inAppMessageConfig }
    var inAppMessage: InAppMessage { inAppMessageConfig }

    private init(
        workspace: Workspace,
        inAppMessage: InAppMessageConfig,
        user: HackleUser,
        record: Bool,
        scope: InAppMessageEvaluateScope,
        platformType: PlatformType,
        timestamp: Date
    ) {
        self.workspace = workspace
        self.inAppMessageConfig = inAppMessage
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
        inAppMessage: InAppMessageConfig,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        platformType: PlatformType,
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
