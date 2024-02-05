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

    init(inAppMessage: InAppMessage, message: InAppMessage.Message, user: HackleUser, properties: [String: Any]) {
        self.inAppMessage = inAppMessage
        self.message = message
        self.user = user
        self.properties = properties
    }
}
