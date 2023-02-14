//
// Created by yong on 2020/12/11.
//

import Foundation

@objc public class User: NSObject {

    @objc public let id: String?
    @objc public let userId: String?
    @objc public let deviceId: String?
    @objc public let identifiers: [String: String]
    @objc public let properties: [String: Any]

    init(id: String?, userId: String?, deviceId: String?, identifiers: [String: String], properties: [String: Any]) {
        self.id = id
        self.userId = userId
        self.deviceId = deviceId
        self.identifiers = identifiers
        self.properties = properties
    }

    @objc public static func builder() -> HackleUserBuilder {
        HackleUserBuilder()
    }

    public override var description: String {
        "User(id=\(id.orNil), userId=\(userId.orNil), deviceId=\(deviceId.orNil), identifiers=\(identifiers), properties=\(properties))"
    }

    @objc public func toBuilder() -> HackleUserBuilder {
        HackleUserBuilder(user: self)
    }
}

extension User {
    typealias Id = String
}

@objc public class HackleUserBuilder: NSObject {

    private var id: String? = nil
    private var userId: String? = nil
    private var deviceId: String? = nil
    private var identifiers: IdentifiersBuilder = IdentifiersBuilder()
    private var properties: PropertiesBuilder = PropertiesBuilder()

    public override init() {
        super.init()
    }

    init(user: User) {
        super.init()
        id(user.id)
        userId(user.userId)
        deviceId(user.deviceId)
        identifiers.add(user.identifiers)
        properties.add(user.properties)
    }

    @discardableResult
    @objc public func id(_ id: String?) -> HackleUserBuilder {
        self.id = id
        return self
    }

    @discardableResult
    @objc public func userId(_ userId: String?) -> HackleUserBuilder {
        self.userId = userId
        return self
    }

    @discardableResult
    @objc public func deviceId(_ deviceId: String?) -> HackleUserBuilder {
        self.deviceId = deviceId
        return self
    }

    @discardableResult
    @objc public func identifier(_ type: String, _ value: String) -> HackleUserBuilder {
        self.identifiers.add(type, value)
        return self
    }

    @discardableResult
    @objc public func property(_ key: String, _ value: Any?) -> HackleUserBuilder {
        self.properties.add(key, value)
        return self
    }

    @objc public func build() -> User {
        User(
            id: id,
            userId: userId,
            deviceId: deviceId,
            identifiers: identifiers.build(),
            properties: properties.build()
        )
    }
}
