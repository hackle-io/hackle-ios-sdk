import Foundation

protocol InAppMessagePresentationContextResolver {
    func resolve(requset: InAppMessagePresentRequest) throws -> InAppMessagePresentationContext
}

class DefaultInAppMessagePresentationContextResolver: InAppMessagePresentationContextResolver {

    private let core: HackleCore
    private let layoutEvaluator: Evaluator

    init(core: HackleCore, layoutEvaluator: Evaluator) {
        self.core = core
        self.layoutEvaluator = layoutEvaluator
    }

    func resolve(requset: InAppMessagePresentRequest) throws -> InAppMessagePresentationContext {
        let layoutRequest = requset.toLayoutRequest()
        let layoutEvaluation: InAppMessageLayoutEvaluation = try core.evaluate(request: layoutRequest, context: Evaluators.context(), evaluator: layoutEvaluator)
        let presentationContext = InAppMessagePresentationContext.of(request: requset, evaluation: layoutEvaluation)
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
        requset: InAppMessageDeliverRequest,
        workspace: Workspace,
        inAppMessage: InAppMessage,
        user: HackleUser,
        evaluation: InAppMessageEvaluation
    ) -> InAppMessagePresentRequest {
        return InAppMessagePresentRequest(
            dispatchId: requset.dispatchId,
            workspace: workspace,
            inAppMessage: inAppMessage,
            user: user,
            requestedAt: requset.requestedAt,
            evaluation: evaluation,
            properties: requset.properties
        )
    }
}
