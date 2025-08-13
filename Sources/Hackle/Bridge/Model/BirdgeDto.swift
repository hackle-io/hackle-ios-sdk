//
//  BirdgeDto.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

typealias UserDto = [String: Any]
typealias EventDto = [String: Any]
typealias DecisionDto = [String: Any]
typealias FeatureFlagDecisionDto = [String: Any]
typealias PropertyOperationsDto = [String: [String: Any]]
typealias HackleSubscriptionOperationsDto = [String: String]

extension User {

    func toDto() -> UserDto {
        let dictionary: [String: Any?] = [
            "id": id,
            "userId": userId,
            "deviceId": deviceId,
            "identifiers": identifiers,
            "properties": properties
        ]
        let sanitized = dictionary.compactMapValues {
            $0
        }
        return sanitized
    }

    static func from(dto: UserDto) -> User? {
        let builder = User.builder()
        if let id = dto["id"] as? String {
            builder.id(id)
        }
        if let userId = dto["userId"] as? String {
            builder.userId(userId)
        }
        if let deviceId = dto["deviceId"] as? String {
            builder.deviceId(deviceId)
        }
        if let identifiers = dto["identifiers"] as? [String: String] {
            builder.identifiers(identifiers)
        }
        if let properties = dto["properties"] as? [String: Any] {
            builder.properties(properties)
        }
        return builder.build()
    }
}

extension Event {

    static func from(dto: EventDto) -> Event? {
        guard let key = dto["key"] as? String else {
            return nil
        }
        let builder = Event.builder(key)
        if let value = dto["value"] as? Double {
            builder.value(value)
        }
        if let properties = dto["properties"] as? [String: Any] {
            builder.properties(properties)
        }
        return builder.build()
    }
}

extension Decision {

    func toDto() -> DecisionDto {
        var dictionary: [String: Any] = [:]
        dictionary["variation"] = variation
        dictionary["reason"] = reason
        dictionary["config"] = ["parameters": parameters]
        return dictionary.compactMapValues {
            $0
        }
    }
}

extension FeatureFlagDecision {

    func toDto() -> FeatureFlagDecisionDto {
        var dictionary: [String: Any] = [:]
        dictionary["isOn"] = isOn
        dictionary["reason"] = reason
        dictionary["config"] = ["parameters": parameters]
        return dictionary.compactMapValues {
            $0
        }
    }
}

extension PropertyOperations {

    static func from(dto: PropertyOperationsDto) -> PropertyOperations {
        let builder = PropertyOperationsBuilder()
        for (operation, properties) in dto {
            guard let operation = PropertyOperation(rawValue: operation) else {
                continue
            }

            switch operation {
            case PropertyOperation.set:
                properties.forEach { key, value in
                    builder.set(key, value)
                }
            case PropertyOperation.setOnce:
                properties.forEach { key, value in
                    builder.setOnce(key, value)
                }
            case PropertyOperation.unset:
                properties.forEach { key, value in
                    builder.unset(key)
                }
            case PropertyOperation.increment:
                properties.forEach { key, value in
                    builder.increment(key, value)
                }
            case PropertyOperation.append:
                properties.forEach { key, value in
                    builder.append(key, value)
                }
            case .appendOnce:
                properties.forEach { key, value in
                    builder.appendOnce(key, value)
                }
            case .prepend:
                properties.forEach { key, value in
                    builder.prepend(key, value)
                }
            case .prependOnce:
                properties.forEach { key, value in
                    builder.prependOnce(key, value)
                }
            case .remove:
                properties.forEach { key, value in
                    builder.remove(key, value)
                }
            case .clearAll:
                properties.forEach { key, value in
                    builder.clearAll()
                }
            }
        }
        return builder.build()
    }
}

extension HackleSubscriptionOperations {
    
    static func from(dto: HackleSubscriptionOperationsDto) -> HackleSubscriptionOperations {
        let builder = HackleSubscriptionOperations.builder()
        for (key, value) in dto {
            guard let status = HackleSubscriptionStatus(rawValue: value) else {
                continue
            }
            builder.custom(key, status: status)
        }
        return builder.build()
    }
}
