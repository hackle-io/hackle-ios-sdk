//
//  InAppMessageRequest.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation


class InAppMessageRequest: EvaluatorRequest, Equatable, CustomStringConvertible {
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

    static func ==(lhs: InAppMessageRequest, rhs: InAppMessageRequest) -> Bool {
        lhs.key == rhs.key
    }

    var description: String {
        "EvaluatorRequest(type=IN_APP_MESSAGE, key=\(inAppMessage.key))"
    }
}
