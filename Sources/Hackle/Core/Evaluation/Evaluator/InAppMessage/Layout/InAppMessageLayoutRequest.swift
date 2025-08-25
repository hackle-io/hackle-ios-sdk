import Foundation

class InAppMessageLayoutRequest: EvaluatorRequest, Equatable, CustomStringConvertible {
    let key: EvaluatorKey
    let workspace: Workspace
    let user: HackleUser
    let inAppMessage: InAppMessage

    init(
        workspace: Workspace,
        user: HackleUser,
        inAppMessage: InAppMessage
    ) {
        self.key = EvaluatorKey(type: .inAppMessage, id: inAppMessage.id)
        self.workspace = workspace
        self.user = user
        self.inAppMessage = inAppMessage
    }

    static func ==(lhs: InAppMessageLayoutRequest, rhs: InAppMessageLayoutRequest) -> Bool {
        lhs.key == rhs.key
    }

    var description: String {
        "InAppMessageLayoutRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }
}
