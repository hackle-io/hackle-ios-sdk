//
//  InvokeDto.swift
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
        return dictionary.compactMapValues {
            $0
        }
    }

    static func from(dto: UserDto) -> User {
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
                for (key, value) in properties {
                    builder.set(key, value)
                }
            case PropertyOperation.setOnce:
                for (key, value) in properties {
                    builder.setOnce(key, value)
                }
            case PropertyOperation.unset:
                for (key, _) in properties {
                    builder.unset(key)
                }
            case PropertyOperation.increment:
                for (key, value) in properties {
                    builder.increment(key, value)
                }
            case PropertyOperation.append:
                for (key, value) in properties {
                    builder.append(key, value)
                }
            case .appendOnce:
                for (key, value) in properties {
                    builder.appendOnce(key, value)
                }
            case .prepend:
                for (key, value) in properties {
                    builder.prepend(key, value)
                }
            case .prependOnce:
                for (key, value) in properties {
                    builder.prependOnce(key, value)
                }
            case .remove:
                for (key, value) in properties {
                    builder.remove(key, value)
                }
            case .clearAll:
                for (_, _) in properties {
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

struct HackleInAppMessageDto: Codable {
    let key: Int64
}

struct HackleInAppMessageViewDto: Codable {
    let id: String
    let inAppMessage: HackleInAppMessageDto
}

extension InAppMessageView {
    nonisolated func toDto() -> HackleInAppMessageViewDto {
        return HackleInAppMessageViewDto(
            id: id,
            inAppMessage: inAppMessage.toDto()
        )
    }
}

extension HackleInAppMessage {
    func toDto() -> HackleInAppMessageDto {
        return HackleInAppMessageDto(
            key: key
        )
    }
}

struct HandleInAppMessageViewInvocationDto: Codable {
    let viewId: String
    let handleTypes: [String]
    let event: InAppMessageViewEventDto
}

struct InAppMessageActionDto: Codable {
    var behavior: String
    var type: String
    var value: String?
}

struct InAppMessageViewEventDto: Codable {
    let type: String
    let action: InAppMessageActionDto?
    let element: InAppMessageElementDto?
}

struct InAppMessageElementDto: Codable {
    let elementId: String?
    let area: String?
}

extension InAppMessageActionDto {
    func toAction() throws -> InAppMessage.Action {
        return try InAppMessage.Action(
            behavior: Enums.parse(rawValue: behavior),
            type: Enums.parse(rawValue: type),
            value: value
        )
    }
}
