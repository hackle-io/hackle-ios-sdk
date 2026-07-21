import Foundation

protocol InAppMessageDeliverProcessor {
    func process(request: InAppMessageDeliverRequest) async -> InAppMessageDeliverResponse
}

class DefaultInAppMessageDeliverProcessor: InAppMessageDeliverProcessor {

    private let userManager: UserManager
    private let userDecoreator: UserDecorator
    private let identifierChecker: InAppMessageIdentifierChecker
    private let evaluator: InAppMessageDeliverEvaluator
    private let presentProcessor: InAppMessagePresentProcessor

    init(
        userManager: UserManager,
        userDecoreator: UserDecorator,
        identifierChecker: InAppMessageIdentifierChecker,
        evaluator: InAppMessageDeliverEvaluator,
        presentProcessor: InAppMessagePresentProcessor
    ) {
        self.userManager = userManager
        self.userDecoreator = userDecoreator
        self.identifierChecker = identifierChecker
        self.evaluator = evaluator
        self.presentProcessor = presentProcessor
    }

    func process(request: InAppMessageDeliverRequest) async -> InAppMessageDeliverResponse {
        Log.debug("InAppMessage Deliver Request: \(request)")

        do {
            let response = try await deliver(request: request)
            Log.debug("InAppMessage Deliver Response: \(response)")
            return response
        } catch {
            Log.error("Failed to process InAppMessage Deliver: \(error)")
            return InAppMessageDeliverResponse.of(request: request, code: .exception)
        }
    }

    private func deliver(request: InAppMessageDeliverRequest) async throws -> InAppMessageDeliverResponse {

        // check User
        let user = userManager.hackleUser()
            .decorateWith(docorator: userDecoreator)

        let isIdentifierChanged = identifierChecker.isIdentifierChanged(old: request.identifiers, new: user.identifiers)
        if isIdentifierChanged {
            return InAppMessageDeliverResponse.of(request: request, code: .identifierChanged)
        }

        // evaluate (dedup + re-evaluate)
        let response = try await evaluator.evaluate(request: request, user: user)
        return await resolve(request: request, user: user, response: response)
    }

    private func resolve(
        request: InAppMessageDeliverRequest,
        user: HackleUser,
        response: InAppMessageDeliverEvaluateResponse
    ) async -> InAppMessageDeliverResponse {
        if !response.isEligible {
            return InAppMessageDeliverResponse.of(request: request, code: response.code ?? .ineligible)
        }

        guard let evaluation = response.evaluation else {
            return InAppMessageDeliverResponse.of(request: request, code: .ineligible)
        }

        let presentRequest = InAppMessagePresentRequest.of(
            request: request,
            user: user,
            evaluation: evaluation
        )
        let presentResponse = await presentProcessor.process(request: presentRequest)

        return InAppMessageDeliverResponse.of(request: request, code: .present, presentResponse: presentResponse)
    }
}
