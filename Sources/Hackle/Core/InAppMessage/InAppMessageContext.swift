//
//  InAppMessageContext.swift
//  Hackle
//
//  Created by yong on 2023/06/08.
//

import Foundation


class InAppMessageContext {

    let inAppMessage: InAppMessage
    let message: InAppMessage.Message
    let properties: [String: Any]

    init(inAppMessage: InAppMessage, message: InAppMessage.Message, properties: [String: Any]) {
        self.inAppMessage = inAppMessage
        self.message = message
        self.properties = properties
    }
}
