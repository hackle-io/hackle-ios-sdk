import Foundation

final class InAppMessageEligibilityEvaluateResponse: EvaluateResponse {
    let user: HackleUser
    let workspace: Workspace
    let eligibilityEvaluation: InAppMessageEligibilityEvaluation
    let references: [Evaluation]
    let layout: InAppMessageLayoutEvaluateResponse?

    var evaluation: Evaluation { eligibilityEvaluation }

    init(
        user: HackleUser,
        workspace: Workspace,
        evaluation: InAppMessageEligibilityEvaluation,
        references: [Evaluation],
        layout: InAppMessageLayoutEvaluateResponse?
    ) {
        self.user = user
        self.workspace = workspace
        self.eligibilityEvaluation = evaluation
        self.references = references
        self.layout = layout
    }

    static func of(
        request: InAppMessageEligibilityEvaluateRequest,
        context: EvaluatorContext,
        result: InAppMessageEligibilityEvaluateResult
    ) -> InAppMessageEligibilityEvaluateResponse {
        InAppMessageEligibilityEvaluateResponse(
            user: request.user,
            workspace: request.workspace,
            evaluation: InAppMessageEligibilityEvaluation(entity: request.inAppMessage, result: result),
            references: context.references,
            layout: context.get(InAppMessageLayoutEvaluateResponse.self)
        )
    }
}
