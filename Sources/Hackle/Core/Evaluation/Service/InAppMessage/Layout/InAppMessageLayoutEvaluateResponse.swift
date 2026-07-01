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
        let experimentEvaluation: ExperimentEvaluation?
        if let experimentContext = request.inAppMessage.messageContext.experimentContext,
           let experiment = request.workspace.getExperimentOrNil(experimentKey: experimentContext.key) {
            experimentEvaluation = context.get(experiment) as? ExperimentEvaluation
        } else {
            experimentEvaluation = nil
        }
        return InAppMessageLayoutEvaluateResponse(
            user: request.user,
            workspace: request.workspace,
            evaluation: InAppMessageLayoutEvaluation(entity: request.inAppMessage, result: result, properties: context.properties),
            references: context.references,
            experiment: experimentEvaluation
        )
    }
}
