import Foundation

protocol InAppMessageDeliverProcessor {
    func process(request: InAppMessageDeliverRequest) throws -> InAppMessageDeliverResponse
}

class DefaultInAppMessageDeliverProcessor: InAppMessageDeliverProcessor {

    private let workspaceFetcher: WorkspaceFetcher
    private let userManager: UserManager
    private let identifierChecker: InAppMessageIdentifierChecker
    private let evaluator: InAppMessageEvaluator
    private let presentProcessor: InAppMessagePresentProcessor

    init(
        workspaceFetcher: WorkspaceFetcher,
        userManager: UserManager,
        identifierChecker: InAppMessageIdentifierChecker,
        evaluator: InAppMessageEvaluator,
        presentProcessor: InAppMessagePresentProcessor
    ) {
        self.workspaceFetcher = workspaceFetcher
        self.userManager = userManager
        self.identifierChecker = identifierChecker
        self.evaluator = evaluator
        self.presentProcessor = presentProcessor
    }

    func process(request: InAppMessageDeliverRequest) throws -> InAppMessageDeliverResponse {
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
        let isIdentifierChanged = identifierChecker.isIdentifierChanged(old: request.identifiers, new: user.identifiers)
        if isIdentifierChanged {
            return InAppMessageDeliverResponse.of(request: request, code: .identifierChanged)
        }

        // check Evaluation
        let evaluation: InAppMessageEvaluation
        if inAppMessage.evaluateContext.atDeliverTime {
            evaluation = try evaluator.evaluate(workspace: workspace, inAppMessage: inAppMessage, user: user, timestamp: request.requestedAt)
            Log.debug("InAppMessage Re-evaluated: evaluation: \(evaluation), request: \(request)")
        } else {
            evaluation = request.evaluation
        }
        if !evaluation.isEligible {
            return InAppMessageDeliverResponse.of(request: request, code: .ineligible)
        }

        let presentRequest = InAppMessagePresentRequest.of(requset: request, workspace: workspace, inAppMessage: inAppMessage, user: user, evaluation: evaluation)
        let presentResponse = try presentProcessor.process(request: presentRequest)

        return InAppMessageDeliverResponse.of(request: request, code: .present, presentResponse: presentResponse)
    }
}
