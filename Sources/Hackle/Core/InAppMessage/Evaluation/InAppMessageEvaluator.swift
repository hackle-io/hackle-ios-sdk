import Foundation

protocol InAppMessageEvaluator {
    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws -> InAppMessageEvaluation
}

class DefaultInAppMessageEvaluator: InAppMessageEvaluator {

    private let core: HackleCore
    private let eligibilityEvaluator: Evaluator

    init(core: HackleCore, eligibilityEvaluator: Evaluator) {
        self.core = core
        self.eligibilityEvaluator = eligibilityEvaluator
    }

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws -> InAppMessageEvaluation {
        let request = InAppMessageEligibilityRequest(workspace: workspace, user: user, inAppMessage: inAppMessage, timestamp: timestamp)
        let evaluation: InAppMessageEligibilityEvaluation = try core.evaluate(request: request, context: Evaluators.context(), evaluator: eligibilityEvaluator)
        return InAppMessageEvaluation.from(evaluation: evaluation)
    }
}
