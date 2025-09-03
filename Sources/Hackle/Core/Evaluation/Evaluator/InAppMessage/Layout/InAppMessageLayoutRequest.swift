import Foundation

class InAppMessageLayoutRequest: InAppMessageEvaluatorRequest {
    let workspace: Workspace
    let user: HackleUser
    let inAppMessage: InAppMessage

    init(
        workspace: Workspace,
        user: HackleUser,
        inAppMessage: InAppMessage
    ) {
        self.workspace = workspace
        self.user = user
        self.inAppMessage = inAppMessage
    }
}

extension InAppMessageLayoutRequest: Equatable, CustomStringConvertible {
    var description: String {
        "InAppMessageLayoutRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }

    static func ==(lhs: InAppMessageLayoutRequest, rhs: InAppMessageLayoutRequest) -> Bool {
        lhs.key == rhs.key
    }

    static func of(request: InAppMessageEvaluatorRequest) -> InAppMessageLayoutRequest {
        if let layoutRequest = request as? InAppMessageLayoutRequest {
            return layoutRequest
        }
        return InAppMessageLayoutRequest(
            workspace: request.workspace,
            user: request.user,
            inAppMessage: request.inAppMessage
        )
    }
}
