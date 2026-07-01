import Foundation

protocol InAppMessageLayoutResolver {
    func resolve(workspace: WorkspaceConfig, inAppMessage: InAppMessage, user: HackleUser) throws -> InAppMessageLayoutEvaluation
}

class DefaultInAppMessageLayoutResolver: InAppMessageLayoutResolver {

    private let evaluateProcessor: EvaluateProcessor

    init(evaluateProcessor: EvaluateProcessor) {
        self.evaluateProcessor = evaluateProcessor
    }

    func resolve(workspace: WorkspaceConfig, inAppMessage: InAppMessage, user: HackleUser) throws -> InAppMessageLayoutEvaluation {
        let layoutRequest = InAppMessageLayoutLocalEvaluateRequest.of(
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            scope: .deliver
        )
        let response = try evaluateProcessor.inAppMessage(layoutRequest)
        return response.layoutEvaluation
    }
}
