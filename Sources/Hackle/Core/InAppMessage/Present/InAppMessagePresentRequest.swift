import Foundation

class InAppMessagePresentRequest {

    let dispatchId: String
    let workspace: Workspace
    let inAppMessage: InAppMessage
    let user: HackleUser
    let requestedAt: Date
    let evaluation: InAppMessageEvaluation
    let properties: [String: Any]

    init(
        dispatchId: String,
        workspace: Workspace,
        inAppMessage: InAppMessage,
        user: HackleUser,
        requestedAt: Date,
        evaluation: InAppMessageEvaluation,
        properties: [String: Any]
    ) {
        self.dispatchId = dispatchId
        self.workspace = workspace
        self.inAppMessage = inAppMessage
        self.user = user
        self.requestedAt = requestedAt
        self.evaluation = evaluation
        self.properties = properties
    }
}

extension InAppMessagePresentRequest: CustomStringConvertible {
    var description: String {
        "InAppMessagePresentRequest(dispatchId: \(dispatchId), inAppMessage: \(inAppMessage), user: \(user.identifiers), requestedAt: \(requestedAt), evaluatio: \(evaluation), properties: \(properties))"
    }
}
