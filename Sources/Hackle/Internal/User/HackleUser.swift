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
}


extension HackleUser {

    static func builder() -> InternalHackleUserBuilder {
        InternalHackleUserBuilder()
    }

    static func of(userId: String) -> HackleUser {
        HackleUser.of(user: Hackle.user(id: userId), hackleProperties: [String: Any]())
    }

    static func of(user: User, hackleProperties: [String: Any]) -> HackleUser {
        let identifiers = IdentifiersBuilder()
            .add(user.identifiers)
            .add(.id, user.id)
            .add(.user, user.userId)
            .add(.device, user.deviceId)
            .build()


        let properties = PropertiesBuilder()
            .add(user.properties)
            .build()

        return HackleUser(identifiers: identifiers, properties: properties, hackleProperties: hackleProperties)
    }

    func toBuilder() -> InternalHackleUserBuilder {
        InternalHackleUserBuilder(user: self)
    }

    var userId: String? {
        identifiers[IdentifierType.user.rawValue]
    }

    var deviceId: String? {
        identifiers[IdentifierType.device.rawValue]
    }

    var sessionId: String? {
        identifiers[IdentifierType.session.rawValue]
    }
}

class InternalHackleUserBuilder {

    private let identifiers = IdentifiersBuilder()
    private let properties = PropertiesBuilder()
    private let hackleProperties = PropertiesBuilder()

    init() {
    }

    init(user: HackleUser) {
        identifiers.add(user.identifiers)
        properties.add(user.properties)
        hackleProperties.add(user.hackleProperties)
    }

    @discardableResult
    func identifiers(_ identifiers: [String: String], overwrite: Bool = true) -> InternalHackleUserBuilder {
        self.identifiers.add(identifiers, overwrite: overwrite)
        return self
    }

    @discardableResult
    func identifier(_ type: String, _ value: String?, overwrite: Bool = true) -> InternalHackleUserBuilder {
        self.identifiers.add(type, value, overwrite: overwrite)
        return self
    }

    @discardableResult
    func identifier(_ type: IdentifierType, _ value: String?, overwrite: Bool = true) -> InternalHackleUserBuilder {
        self.identifiers.add(type, value, overwrite: overwrite)
        return self
    }

    @discardableResult
    func properties(_ properties: [String: Any]) -> InternalHackleUserBuilder {
        self.properties.add(properties)
        return self
    }

    @discardableResult
    func property(_ key: String, _ value: Any?) -> InternalHackleUserBuilder {
        self.properties.add(key, value)
        return self
    }

    @discardableResult
    func hackleProperties(_ properties: [String: Any]) -> InternalHackleUserBuilder {
        self.hackleProperties.add(properties)
        return self
    }

    @discardableResult
    func hackleProperty(_ key: String, _ value: Any?) -> InternalHackleUserBuilder {
        self.hackleProperties.add(key, value)
        return self
    }

    func build() -> HackleUser {
        HackleUser(
            identifiers: identifiers.build(),
            properties: properties.build(),
            hackleProperties: hackleProperties.build()
        )
    }
}
