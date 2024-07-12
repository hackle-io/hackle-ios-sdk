import Foundation

enum IdentifierType: String, Codable {
    case id = "$id"
    case user = "$userId"
    case device = "$deviceId"
    case session = "$sessionId"
    case hackleDevice = "$hackleDeviceId"
}

struct Identifier: Hashable, CustomStringConvertible {

    let type: String
    let value: String

    init(type: String, value: String) {
        self.type = type
        self.value = value
    }

    var description: String {
        "Identifier(type: \(type), value: \(value))"
    }
}

typealias Identifiers = [String: String]

extension Identifiers {

    static func from(user: User) -> Identifiers {
        IdentifiersBuilder()
            .add(user.identifiers)
            .add(.id, user.id)
            .add(.user, user.userId)
            .add(.device, user.deviceId)
            .build()
    }

    func contains(identifier: Identifier) -> Bool {
        contains(type: identifier.type, value: identifier.value)
    }

    func contains(type: String, value: String) -> Bool {
        value == self[type]
    }
}

class IdentifiersBuilder {

    private var identifiers = Identifiers()

    private static let MAX_IDENTIFIER_TYPE_LENGTH = 128
    private static let MAX_IDENTIFIER_VALUE_LENGTH = 512

    @discardableResult
    func add(_ identifiers: [String: String], overwrite: Bool = true) -> IdentifiersBuilder {
        for (key, value) in identifiers {
            add(key, value, overwrite: overwrite)
        }
        return self
    }

    @discardableResult
    func add(_ type: IdentifierType, _ value: String?, overwrite: Bool = true) -> IdentifiersBuilder {
        add(type.rawValue, value, overwrite: overwrite)
    }

    @discardableResult
    func add(_ type: String, _ value: String?, overwrite: Bool = true) -> IdentifiersBuilder {
        if !overwrite && identifiers[type] != nil {
            return self
        }

        if let value = value, isValid(type: type, value: value) {
            identifiers[type] = value
        }
        return self
    }

    private func isValid(type: String, value: String) -> Bool {
        if type.count > IdentifiersBuilder.MAX_IDENTIFIER_TYPE_LENGTH {
            return false
        }

        if value.count > IdentifiersBuilder.MAX_IDENTIFIER_VALUE_LENGTH {
            return false
        }

        if value.isEmpty {
            return false
        }

        return true
    }

    func build() -> Identifiers {
        identifiers
    }
}

extension User {
    var resolvedIdentifiers: Identifiers {
        Identifiers.from(user: self)
    }
}
