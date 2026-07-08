import Foundation

protocol InAppMessageLayoutResolver {
    func resolve(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser) throws -> InAppMessageLayoutEvaluateResponse
}

class DefaultInAppMessageLayoutResolver: InAppMessageLayoutResolver {

    private let evaluateProcessor: EvaluateProcessor

    init(evaluateProcessor: EvaluateProcessor) {
        self.evaluateProcessor = evaluateProcessor
    }

    func resolve(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser) throws -> InAppMessageLayoutEvaluateResponse {
        guard let inAppMessageConfig = inAppMessage as? InAppMessageConfig else {
            throw HackleError.error("InAppMessageConfig[\(inAppMessage.key)]")
        }
        let layoutRequest = InAppMessageLayoutLocalEvaluateRequest.of(
            workspace: workspace,
            inAppMessage: inAppMessageConfig,
            user: user,
            scope: .deliver
        )
        return try evaluateProcessor.inAppMessage(layoutRequest)
    }
}
