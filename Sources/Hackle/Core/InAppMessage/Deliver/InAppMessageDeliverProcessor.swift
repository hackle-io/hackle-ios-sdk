import Foundation

protocol InAppMessageDeliverProcessor {
    func process(request: InAppMessageDeliverRequest) -> InAppMessageDeliverResponse
}

class DefaultInAppMessageDeliverProcessor: InAppMessageDeliverProcessor {

    private let workspaceFetcher: WorkspaceFetcher
    private let userManager: UserManager
    private let userDecoreator: UserDecorator
    private let identifierChecker: InAppMessageIdentifierChecker
    private let layoutResolver: InAppMessageLayoutResolver
    private let evaluateProcessor: InAppMessageEvaluateProcessor
    private let presentProcessor: InAppMessagePresentProcessor

    init(
        workspaceFetcher: WorkspaceFetcher,
        userManager: UserManager,
        userDecoreator: UserDecorator,
        identifierChecker: InAppMessageIdentifierChecker,
        layoutResolver: InAppMessageLayoutResolver,
        evaluateProcessor: InAppMessageEvaluateProcessor,
        presentProcessor: InAppMessagePresentProcessor
    ) {
        self.workspaceFetcher = workspaceFetcher
        self.userManager = userManager
        self.userDecoreator = userDecoreator
        self.identifierChecker = identifierChecker
        self.layoutResolver = layoutResolver
        self.evaluateProcessor = evaluateProcessor
        self.presentProcessor = presentProcessor
    }

    func process(request: InAppMessageDeliverRequest) -> InAppMessageDeliverResponse {
        Log.debug("InAppMessage Deliver Request: \(request)")

        do {
            let response = try deliver(request: request)
            Log.debug("InAppMessage Deliver Response: \(response)")
            return response
        } catch {
            Log.error("Failed to process InAppMessage Deliver: \(error)")
            return InAppMessageDeliverResponse.of(request: request, code: .exception)
        }
    }

    private func deliver(request: InAppMessageDeliverRequest) throws -> InAppMessageDeliverResponse {

        // check Workspace
        guard let workspace = workspaceFetcher.fetch() else {
            return InAppMessageDeliverResponse.of(request: request, code: .workspaceNotFound)
        }

        // check InAppMessage
        guard let inAppMessage = workspace.getInAppMessageOrNil(inAppMessageKey: request.inAppMessageKey) else {
            return InAppMessageDeliverResponse.of(request: request, code: .inAppMessageNotFound)
        }

        // check User
        let user = userManager.resolve(user: nil, hackleAppContext: .default)
            .decorateWith(docorator: userDecoreator)
            
        let isIdentifierChanged = identifierChecker.isIdentifierChanged(old: request.identifiers, new: user.identifiers)
        if isIdentifierChanged {
            return InAppMessageDeliverResponse.of(request: request, code: .identifierChanged)
        }

        // resolve layout
        let layoutEvaluation = try layoutResolver.resolve(workspace: workspace, inAppMessage: inAppMessage, user: user)

        // check Evaluation (re-evaluate + dedup)
        let eligibilityRequest = InAppMessageEligibilityRequest(workspace: workspace, user: user, inAppMessage: inAppMessage, timestamp: request.requestedAt)
        let eligibilityEvaluation = try evaluateProcessor.process(type: .deliver, request: eligibilityRequest)
        if !eligibilityEvaluation.isEligible {
            Log.debug("InAppMessage Deliver Ineligible. dispatchId: \(request.dispatchId), reason: \(eligibilityEvaluation.reason)")
            return InAppMessageDeliverResponse.of(request: request, code: .ineligible)
        }

        // present
        let presentRequest = InAppMessagePresentRequest.of(request: request, inAppMessage: inAppMessage, user: user, eligibilityEvaluation: eligibilityEvaluation, layoutEvaluation: layoutEvaluation)
        let presentResponse = try presentProcessor.process(request: presentRequest)

        return InAppMessageDeliverResponse.of(request: request, code: .present, presentResponse: presentResponse)
    }
}
