import Foundation

protocol InAppMessageLayoutResolver {
    func resolve(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser) throws -> InAppMessageLayoutEvaluation
}

class DefaultInAppMessageLayoutResolver: InAppMessageLayoutResolver {

    private let core: HackleCore
    private let layoutEvaluator: any InAppMessageEvaluator

    init(core: HackleCore, layoutEvaluator: any InAppMessageEvaluator) {
        self.core = core
        self.layoutEvaluator = layoutEvaluator
    }

    func resolve(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser) throws -> InAppMessageLayoutEvaluation {
        let request = InAppMessageLayoutRequest(workspace: workspace, user: user, inAppMessage: inAppMessage)
        return try core.inAppMessage(request: request, context: Evaluators.context(), evaluator: layoutEvaluator)
    }
}
