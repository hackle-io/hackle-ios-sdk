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

fileprivate extension InAppMessagePresentRequest {
    func toLayoutRequest() -> InAppMessageLayoutRequest {
        return InAppMessageLayoutRequest(workspace: workspace, user: user, inAppMessage: inAppMessage)
    }
}
