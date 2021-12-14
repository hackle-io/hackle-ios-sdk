//
//  HackleUser.swift
//  Hackle
//
//  Created by yong on 2021/12/13.
//

import Foundation

class HackleUser {

    let id: String
    let properties: [String: Any]?
    let hackleProperties: [String: Any]?

    init(id: String, properties: [String: Any]?, hackleProperties: [String: Any]?) {
        self.id = id
        self.properties = properties
        self.hackleProperties = hackleProperties
    }

    static func of(userId: String) -> HackleUser {
        HackleUser(id: userId, properties: nil, hackleProperties: nil)
    }

    static func of(user: User, hackleProperties: [String: Any]) -> HackleUser {
        HackleUser(id: user.id, properties: user.properties, hackleProperties: hackleProperties)
    }
}
