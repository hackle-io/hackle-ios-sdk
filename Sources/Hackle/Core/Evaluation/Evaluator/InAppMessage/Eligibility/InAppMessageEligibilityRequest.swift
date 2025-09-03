import Foundation

class InAppMessageEligibilityRequest: InAppMessageEvaluatorRequest, Equatable, CustomStringConvertible {
    let workspace: Workspace
    let user: HackleUser
    let inAppMessage: InAppMessage
    let timestamp: Date

    init(workspace: Workspace, user: HackleUser, inAppMessage: InAppMessage, timestamp: Date) {
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
