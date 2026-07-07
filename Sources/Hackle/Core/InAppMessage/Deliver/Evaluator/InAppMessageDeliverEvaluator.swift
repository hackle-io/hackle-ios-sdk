import Foundation

protocol InAppMessageDeliverEvaluator {
    func evaluate(request: InAppMessageDeliverRequest, user: HackleUser) throws -> InAppMessageDeliverEvaluateResponse
}
