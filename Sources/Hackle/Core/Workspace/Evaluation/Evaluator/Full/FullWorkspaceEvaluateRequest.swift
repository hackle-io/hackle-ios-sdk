import Foundation

class FullWorkspaceEvaluateRequest: WorkspaceEvaluateRequest {

    let context: RemoteEvaluateContext
    let policy: WorkspaceEvaluatePolicy
    let base: WorkspaceEvaluationContext?

    init(context: RemoteEvaluateContext, policy: WorkspaceEvaluatePolicy, base: WorkspaceEvaluationContext?) {
        self.context = context
        self.policy = policy
        self.base = base
    }

    static func of(context: RemoteEvaluateContext, base: WorkspaceEvaluationContext?) -> FullWorkspaceEvaluateRequest {
        let policy: WorkspaceEvaluatePolicy = base == nil ? .forceFull : .auto
        return FullWorkspaceEvaluateRequest(context: context, policy: policy, base: base)
    }
}

extension FullWorkspaceEvaluateRequest {

    func toForceFull() -> FullWorkspaceEvaluateRequest {
        if policy == .forceFull {
            return self
        }
        return FullWorkspaceEvaluateRequest(context: context, policy: .forceFull, base: nil)
    }

    func toDto() -> WorkspaceEvaluateRequestDto {
        WorkspaceEvaluateRequestDto(
            policy: policy.rawValue,
            context: context.toDto(),
            base: base?.toDto()
        )
    }
}
