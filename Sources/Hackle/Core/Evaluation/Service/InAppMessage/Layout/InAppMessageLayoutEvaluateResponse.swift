import Foundation

final class InAppMessageLayoutEvaluateResponse: EvaluateResponse {
    let user: HackleUser
    let workspace: Workspace
    let layoutEvaluation: InAppMessageLayoutEvaluation
    let references: [Evaluation]
    let experiment: ExperimentEvaluation?

    var evaluation: Evaluation { layoutEvaluation }

    init(
        user: HackleUser,
        workspace: Workspace,
        evaluation: InAppMessageLayoutEvaluation,
        references: [Evaluation],
        experiment: ExperimentEvaluation?
    ) {
        self.user = user
        self.workspace = workspace
        self.layoutEvaluation = evaluation
        self.references = references
        self.experiment = experiment
    }

    static func of(
        request: InAppMessageLayoutEvaluateRequest,
        context: EvaluatorContext,
        result: InAppMessageLayoutEvaluateResult
    ) -> InAppMessageLayoutEvaluateResponse {
        let experimentEvaluation = request.inAppMessage.messageContext.experimentContext?.key
            .flatMap { request.workspace.getExperimentOrNil(experimentKey: $0) }
            .flatMap { context.get($0) as? ExperimentEvaluation }
        return InAppMessageLayoutEvaluateResponse(
            user: request.user,
            workspace: request.workspace,
            evaluation: InAppMessageLayoutEvaluation(entity: request.inAppMessage, result: result),
            references: context.references,
            experiment: experimentEvaluation
        )
    }
}
