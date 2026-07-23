import Foundation

extension User {

    func identifierEquals(other: User?) -> Bool {
        guard let other = other else {
            return false
        }
        return userId == other.userId && deviceId == other.deviceId
    }

    func mergeWith(other: User?) -> User {
        guard let other = other else {
            return self
        }

        if identifierEquals(other: other) {
            return User(
                id: id,
                userId: userId,
                deviceId: deviceId,
                identifiers: identifiers,
                properties: properties.merging(other.properties) { current, _ in
                    current
                }
            )
        }

        return self
    }

    func with(properties: [String: Any]) -> User {
        User(
            id: id,
            userId: userId,
            deviceId: deviceId,
            identifiers: identifiers,
            properties: properties
        )
    }

    func with(device: Device) -> User {
        let builder = toBuilder()
        if id == nil {
            builder.id(device.id)
        }
        if deviceId == nil {
            builder.deviceId(device.id)
        }
        return builder.build()
    }

    var resolvedIdentifiers: Identifiers {
        Identifiers.from(user: self)
    }
}
