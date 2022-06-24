//
//  HackleUser.swift
//  Hackle
//
//  Created by yong on 2021/12/13.
//

import Foundation

class HackleUser {

    let identifiers: [String: String]
    let properties: [String: Any]
    let hackleProperties: [String: Any]

    init(identifiers: [String: String], properties: [String: Any], hackleProperties: [String: Any]) {
        self.identifiers = identifiers
        self.properties = properties
        self.hackleProperties = hackleProperties
    }

    static func of(userId: String) -> HackleUser {
        HackleUser.of(user: Hackle.user(id: userId), hackleProperties: [String: Any]())
    }

    static func of(user: User, hackleProperties: [String: Any]) -> HackleUser {
        let identifiers = IdentifiersBuilder()
            .add(identifiers: user.identifiers)
            .add(type: IdentifierType.id, value: user.id)
            .add(type: IdentifierType.user, value: user.userId)
            .add(type: IdentifierType.device, value: user.deviceId)
            .build()


        let properties = PropertiesBuilder()
            .add(properties: user.properties)
            .build()

        return HackleUser(identifiers: identifiers, properties: properties, hackleProperties: hackleProperties)
    }
}
