import Foundation

protocol InAppMessagePresentationContextResolver {
    func resolve(request: InAppMessagePresentRequest) throws -> InAppMessagePresentationContext
}

class DefaultInAppMessagePresentationContextResolver: InAppMessagePresentationContextResolver {

    private let core: HackleCore
    private let layoutEvaluator: Evaluator

    init(core: HackleCore, layoutEvaluator: Evaluator) {
        self.core = core
        self.layoutEvaluator = layoutEvaluator
    }

    func resolve(request: InAppMessagePresentRequest) throws -> InAppMessagePresentationContext {
        let layoutRequest = request.toLayoutRequest()
        let layoutEvaluation: InAppMessageLayoutEvaluation = try core.evaluate(request: layoutRequest, context: Evaluators.context(), evaluator: layoutEvaluator)
        let presentationContext = InAppMessagePresentationContext.of(request: request, evaluation: layoutEvaluation)
        Log.debug("InAppMessage PresentationContext resolved: \(presentationContext)")
        return presentationContext
    }
}

extension InAppMessagePresentRequest {

    fileprivate func toLayoutRequest() -> InAppMessageLayoutRequest {
        return InAppMessageLayoutRequest(
            workspace: workspace,
            user: user,
            inAppMessage: inAppMessage
        )
    }

    static func of(
        request: InAppMessageDeliverRequest,
        workspace: Workspace,
        inAppMessage: InAppMessage,
        user: HackleUser,
        evaluation: InAppMessageEvaluation
    ) -> InAppMessagePresentRequest {
        return InAppMessagePresentRequest(
            dispatchId: request.dispatchId,
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            requestedAt: request.requestedAt,
            evaluation: evaluation,
            properties: request.properties
        )
    }
}
