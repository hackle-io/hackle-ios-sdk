import Foundation

class InAppMessageEligibilityRequest: EvaluatorRequest, Equatable, CustomStringConvertible {
    let key: EvaluatorKey
    let workspace: Workspace
    let user: HackleUser
    let inAppMessage: InAppMessage
    let timestamp: Date

    init(workspace: Workspace, user: HackleUser, inAppMessage: InAppMessage, timestamp: Date) {
        self.key = EvaluatorKey(type: .inAppMessage, id: inAppMessage.id)
        self.workspace = workspace
        self.user = user
        self.inAppMessage = inAppMessage
        self.timestamp = timestamp
    }

    static func ==(lhs: InAppMessageEligibilityRequest, rhs: InAppMessageEligibilityRequest) -> Bool {
        lhs.key == rhs.key
    }

    var description: String {
        "InAppMessageEligibilityRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }
}
