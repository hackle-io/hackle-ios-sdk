import Foundation

class InAppMessageDeliverRequest {
    let dispatchId: String
    let inAppMessageKey: InAppMessage.Key
    let identifiers: Identifiers
    let requestedAt: Date
    let evaluation: InAppMessageEvaluation
    let properties: [String: Any]

    init(
        dispatchId: String,
        inAppMessageKey: InAppMessage.Key,
        identifiers: Identifiers,
        requestedAt: Date,
        evaluation: InAppMessageEvaluation,
        properties: [String: Any]
    ) {
        self.dispatchId = dispatchId
        self.inAppMessageKey = inAppMessageKey
        self.identifiers = identifiers
        self.requestedAt = requestedAt
        self.evaluation = evaluation
        self.properties = properties
    }
}

extension InAppMessageDeliverRequest: CustomStringConvertible {
    var description: String {
        "InAppMessageDeliverRequest(dispatchId: \(dispatchId), inAppMessageKey: \(inAppMessageKey), identifiers: \(identifiers), requestedAt: \(requestedAt), evaluation: \(evaluation), properties: \(properties))"
    }
}
