//
// Created by yong on 2020/12/11.
//

import Foundation

/// Represents a user in the Hackle.
@objc(HackleUser)
public class User: NSObject {

    /// Primary user identifier
    @objc public let id: String?
    /// User-specific identifier
    @objc public let userId: String?
    /// Device-specific identifier
    @objc public let deviceId: String?
    /// Additional user identifiers for targeting
    @objc public let identifiers: [String: String]
    /// Custom user properties
    @objc public let properties: [String: Any]

    init(id: String?, userId: String?, deviceId: String?, identifiers: [String: String], properties: [String: Any]) {
        self.id = id
        self.userId = userId
        self.deviceId = deviceId
        self.identifiers = identifiers
        self.properties = properties
    }

    /// Creates a new user builder.
    ///
    /// - Returns: A ``HackleUserBuilder`` instance for creating users
    @objc public static func builder() -> HackleUserBuilder {
        HackleUserBuilder()
    }

    public override var description: String {
        "User(id=\(id.orNil), userId=\(userId.orNil), deviceId=\(deviceId.orNil), identifiers=\(identifiers), properties=\(properties))"
    }

    /// Creates a builder initialized with this user's current values.
    ///
    /// - Returns: A ``HackleUserBuilder`` instance initialized with this user's data
    @objc public func toBuilder() -> HackleUserBuilder {
        HackleUserBuilder(user: self)
    }
}

extension User {
    typealias Id = String
}

/// Builder for creating ``User`` instances.
///
/// Use this builder to construct user objects with specific identifiers and properties
/// for targeting and personalization.
@objc
public class HackleUserBuilder: NSObject {

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

    /// Sets the user's primary identifier.
    ///
    /// - Parameter id: The primary user identifier
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func id(_ id: String?) -> HackleUserBuilder {
        self.id = id
        return self
    }

    /// Sets the user's user ID.
    ///
    /// - Parameter userId: The user-specific identifier
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func userId(_ userId: String?) -> HackleUserBuilder {
        self.userId = userId
        return self
    }

    /// Sets the user's device identifier.
    ///
    /// - Parameter deviceId: The device-specific identifier
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func deviceId(_ deviceId: String?) -> HackleUserBuilder {
        self.deviceId = deviceId
        return self
    }

    /// Adds a custom identifier for the user.
    ///
    /// - Parameters:
    ///   - type: The identifier type
    ///   - value: The identifier value
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func identifier(_ type: String, _ value: String) -> HackleUserBuilder {
        self.identifiers.add(type, value)
        return self
    }

    /// Adds multiple custom identifiers for the user.
    ///
    /// - Parameter identifiers: A dictionary of identifier types and values
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func identifiers(_ identifiers: [String: String]) -> HackleUserBuilder {
        self.identifiers.add(identifiers)
        return self
    }

    /// Adds a custom property for the user.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The property value
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func property(_ key: String, _ value: Any?) -> HackleUserBuilder {
        self.properties.add(key, value)
        return self
    }

    /// Adds multiple custom properties for the user.
    ///
    /// - Parameter properties: A dictionary of property keys and values
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func properties(_ properties: [String: Any]) -> HackleUserBuilder {
        self.properties.add(properties)
        return self
    }

    /// Builds a ``User`` instance with the configured values.
    ///
    /// - Returns: A new ``User`` instance
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
