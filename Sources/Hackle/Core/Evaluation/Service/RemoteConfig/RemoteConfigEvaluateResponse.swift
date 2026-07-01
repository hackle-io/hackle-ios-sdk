import Foundation

final class RemoteConfigEvaluateResponse: EvaluateResponse {
    let user: HackleUser
    let workspace: Workspace
    let remoteConfigEvaluation: RemoteConfigEvaluation
    let references: [Evaluation]

    var evaluation: Evaluation { remoteConfigEvaluation }

    init(user: HackleUser, workspace: Workspace, evaluation: RemoteConfigEvaluation, references: [Evaluation]) {
        self.user = user
        self.workspace = workspace
        self.remoteConfigEvaluation = evaluation
        self.references = references
    }

    static func of(
        request: RemoteConfigEvaluateRequest,
        context: EvaluatorContext,
        result: RemoteConfigEvaluateResult
    ) -> RemoteConfigEvaluateResponse {
        let properties = PropertiesBuilder()
            .add("requestValueType", request.defaultValue.type.rawValue)
            .add("requestDefaultValue", request.defaultValue.rawValue)
            .add("returnValue", result.value.rawValue)
            .build()
        return RemoteConfigEvaluateResponse(
            user: request.user,
            workspace: request.workspace,
            evaluation: RemoteConfigEvaluation(entity: request.parameter, result: result, properties: properties),
            references: context.references
        )
    }
}
