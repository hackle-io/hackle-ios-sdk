import Foundation

protocol InAppMessageDeliverEvaluator {
    func evaluate(request: InAppMessageDeliverRequest, user: HackleUser) async throws -> InAppMessageDeliverEvaluateResponse
}
