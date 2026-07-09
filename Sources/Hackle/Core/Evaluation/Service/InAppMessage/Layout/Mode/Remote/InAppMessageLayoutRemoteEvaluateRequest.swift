import Foundation

final class InAppMessageLayoutRemoteEvaluateRequest: RemoteEvaluateRequest, InAppMessageLayoutEvaluateRequest, CustomStringConvertible {

    let evaluationWorkspace: WorkspaceEvaluation
    let result: InAppMessageLayoutRemoteEvaluateResult
    let user: HackleUser
    let scope: InAppMessageEvaluateScope
    let record: Bool

    var workspace: Workspace { evaluationWorkspace }
    var entity: Entity { result }
    var remoteResult: RemoteEvaluateResult { result }
    var inAppMessage: InAppMessage { result }

    private init(
        workspace: WorkspaceEvaluation,
        entity: InAppMessageLayoutRemoteEvaluateResult,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        record: Bool
    ) {
        self.evaluationWorkspace = workspace
        self.result = entity
        self.user = user
        self.scope = scope
        self.record = record
    }

    var description: String {
        "InAppMessageLayoutRemoteEvaluateRequest(type=IN_APP_MESSAGE, key=\(result.key))"
    }

    static func of(
        workspace: WorkspaceEvaluation,
        entity: InAppMessageLayoutRemoteEvaluateResult,
        user: HackleUser,
        scope: InAppMessageEvaluateScope,
        record: Bool = true
    ) -> InAppMessageLayoutRemoteEvaluateRequest {
        InAppMessageLayoutRemoteEvaluateRequest(workspace: workspace, entity: entity, user: user, scope: scope, record: record)
    }

    static func of(
        request: InAppMessageEligibilityRemoteEvaluateRequest,
        inAppMessage: InAppMessageLayoutRemoteEvaluateResult
    ) -> InAppMessageLayoutRemoteEvaluateRequest {
        InAppMessageLayoutRemoteEvaluateRequest(
            workspace: request.evaluationWorkspace,
            entity: inAppMessage,
            user: request.user,
            scope: request.scope,
            record: request.record
        )
    }
}
