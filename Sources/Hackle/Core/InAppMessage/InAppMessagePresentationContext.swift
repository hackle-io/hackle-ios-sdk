//
//  InAppMessageContext.swift
//  Hackle
//
//  Created by yong on 2023/06/08.
//

import Foundation


class InAppMessagePresentationContext {

    let inAppMessage: InAppMessage
    let message: InAppMessage.Message
    let user: HackleUser
    let properties: [String: Any]
    let eventInsertId: String
    let decisionReasion: String

    init(inAppMessage: InAppMessage, message: InAppMessage.Message, user: HackleUser, properties: [String: Any], eventInsertId: String, decisionReasion: String) {
        self.inAppMessage = inAppMessage
        self.message = message
        self.user = user
        self.properties = properties
        self.eventInsertId = eventInsertId
        self.decisionReasion = decisionReasion
    }
}
