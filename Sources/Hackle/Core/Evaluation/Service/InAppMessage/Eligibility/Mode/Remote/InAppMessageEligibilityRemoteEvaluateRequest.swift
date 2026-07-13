import Foundation

final class InAppMessageEligibilityRemoteEvaluateRequest: RemoteEvaluateRequest, InAppMessageEligibilityEvaluateRequest, CustomStringConvertible {

    let evaluationWorkspace: WorkspaceEvaluation
    let result: InAppMessageEligibilityRemoteEvaluateResult
    let user: HackleUser
    let record: Bool
    let scope: InAppMessageEvaluateScope
    let platformType: PlatformType
    let timestamp: Date

    var remoteResult: RemoteEvaluateResult { result }
    var inAppMessage: InAppMessage { result }

    private init(
        workspace: WorkspaceEvaluation,
        entity: InAppMessageEligibilityRemoteEvaluateResult,
        user: HackleUser,
        record: Bool,
        scope: InAppMessageEvaluateScope,
        platformType: PlatformType,
        timestamp: Date
    ) {
        self.evaluationWorkspace = workspace
        self.result = entity
        self.user = user
        self.record = record
        self.scope = scope
        self.platformType = platformType
        self.timestamp = timestamp
    }

    var description: String {
        "InAppMessageEligibilityRemoteEvaluateRequest(type=IN_APP_MESSAGE, key=\(result.key))"
    }

    static func of(
        workspace: WorkspaceEvaluation,
        entity: InAppMessageEligibilityRemoteEvaluateResult,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        platformType: PlatformType,
        timestamp: Date,
        record: Bool = true
    ) -> InAppMessageEligibilityRemoteEvaluateRequest {
        InAppMessageEligibilityRemoteEvaluateRequest(
            workspace: workspace,
            entity: entity,
            user: user,
            record: record,
            scope: scope,
            platformType: platformType,
            timestamp: timestamp
        )
    }
}
