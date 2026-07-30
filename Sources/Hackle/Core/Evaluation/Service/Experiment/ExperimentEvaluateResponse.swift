import Foundation

final class ExperimentEvaluateResponse: EvaluateResponse {
    let user: HackleUser
    let workspace: Workspace
    let experimentEvaluation: ExperimentEvaluation
    let references: [Evaluation]

    var evaluation: Evaluation { experimentEvaluation }

    init(user: HackleUser, workspace: Workspace, evaluation: ExperimentEvaluation, references: [Evaluation]) {
        self.user = user
        self.workspace = workspace
        self.experimentEvaluation = evaluation
        self.references = references
    }

    static func of(
        request: ExperimentEvaluateRequest,
        context: EvaluatorContext,
        result: ExperimentEvaluateResult
    ) -> ExperimentEvaluateResponse {
        ExperimentEvaluateResponse(
            user: request.user,
            workspace: request.workspace,
            evaluation: ExperimentEvaluation(entity: request.experiment, result: result),
            references: context.references
        )
    }
}
