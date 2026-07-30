import Foundation

protocol InAppMessageDeliverProcessor {
    func process(request: InAppMessageDeliverRequest) async -> InAppMessageDeliverResponse
}

class DefaultInAppMessageDeliverProcessor: InAppMessageDeliverProcessor {

    private let userManager: UserManager
    private let userDecorator: UserDecorator
    private let identifierChecker: InAppMessageIdentifierChecker
    private let evaluator: InAppMessageDeliverEvaluator
    private let presentProcessor: InAppMessagePresentProcessor
    private let lifecycleManager: ApplicationLifecycleManager

    init(
        userManager: UserManager,
        userDecorator: UserDecorator,
        identifierChecker: InAppMessageIdentifierChecker,
        evaluator: InAppMessageDeliverEvaluator,
        presentProcessor: InAppMessagePresentProcessor,
        lifecycleManager: ApplicationLifecycleManager
    ) {
        self.userManager = userManager
        self.userDecorator = userDecorator
        self.identifierChecker = identifierChecker
        self.evaluator = evaluator
        self.presentProcessor = presentProcessor
        self.lifecycleManager = lifecycleManager
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

        // check ApplicationState
        // 백그라운드에서는 평가 자체를 하지 않는다. 평가는 노출 이벤트를 기록하므로,
        // 노출되지 않을 메시지를 평가하면 실험 지표가 과계상된다.
        if lifecycleManager.currentState != .foreground {
            return InAppMessageDeliverResponse.of(request: request, code: .applicationNotForeground)
        }

        // check User
        let user = userManager.hackleUser()
            .decorateWith(decorator: userDecorator)

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
            Log.error("InAppMessageDeliverEvaluateResponse.evaluation must not be nil when eligible")
            return InAppMessageDeliverResponse.of(request: request, code: .exception)
        }

        let presentRequest = InAppMessagePresentRequest.of(
            request: request,
            user: user,
            evaluation: evaluation
        )
        let presentResponse = await presentProcessor.process(request: presentRequest)

        return InAppMessageDeliverResponse.of(request: request, code: .deliver, presentResponse: presentResponse)
    }
}
