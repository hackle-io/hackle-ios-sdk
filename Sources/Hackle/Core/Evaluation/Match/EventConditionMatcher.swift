//
//  EventConditionMatcher.swift
//  Hackle
//
//  Created by yong on 2023/06/09.
//

import Foundation


class EventConditionMatcher: ConditionMatcher {

    private let eventValueResolver: EventValueResolver
    private let valueOperatorMatcher: ValueOperatorMatcher

    init(eventValueResolver: EventValueResolver, valueOperatorMatcher: ValueOperatorMatcher) {
        self.eventValueResolver = eventValueResolver
        self.valueOperatorMatcher = valueOperatorMatcher
    }

    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        guard let eventRequest = request as? EvaluatorEventRequest else {
            return false
        }
        let eventValue = try eventValueResolver.resolveOrNil(event: eventRequest.event, key: condition.key)
        return valueOperatorMatcher.matches(userValue: eventValue, match: condition.match)
    }
}

protocol EventValueResolver {
    func resolveOrNil(event: UserEvent, key: Target.Key) throws -> Any?
}

class DefaultEventValueResolver: EventValueResolver {
    func resolveOrNil(event: UserEvent, key: Target.Key) throws -> Any? {
        switch key.type {
        case .eventProperty:
            guard let properties = event.properties() else {
                return nil
            }
            return properties[key.name]
        case .userId, .userProperty, .hackleProperty, .segment, .abTest, .featureFlag, .cohort, .numberOfEventsInDays, .numberOfEventsWithPropertyInDays:
            throw HackleError.error("Unsupported TargetKeyType [\(key.type)]")
        }
    }
}

private extension UserEvent {
    func properties() -> [String: Any]? {
        switch self {
        case let track as UserEvents.Track:
            return track.event.properties
        case let exposure as UserEvents.Exposure:
            return exposure.properties
        case let remoteConfig as UserEvents.RemoteConfig:
            return remoteConfig.properties
        default:
            return nil
        }
    }
}
