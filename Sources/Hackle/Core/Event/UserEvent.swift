//
// Created by yong on 2020/12/11.
//

import Foundation

protocol UserEvent {
    var insertId: String { get }
    var type: UserEventType { get }
    var timestamp: Date { get }
    var user: HackleUser { get }

    func with(user: HackleUser) -> UserEvent
}

enum UserEventType: Int {
    case exposure = 0
    case track = 1
    case remoteConfig = 2
}

enum UserEvents {

    static func exposure(
        user: HackleUser,
        evaluation: ExperimentEvaluation,
        properties: [String: Any],
        internalProperties: [String: Any],
        timestamp: Date
    ) -> UserEvents.Exposure {
        Exposure(
            insertId: UUID().uuidString.lowercased(),
            timestamp: timestamp,
            user: user,
            experiment: evaluation.experiment,
            variationId: evaluation.variationId,
            variationKey: evaluation.variationKey,
            decisionReason: evaluation.reason,
            properties: properties,
            internalProperties: internalProperties
        )
    }

    static func track(
        eventType: EventType,
        event: Event,
        timestamp: Date,
        user: HackleUser
    ) -> UserEvents.Track {
        Track(
            insertId: UUID().uuidString.lowercased(),
            timestamp: timestamp,
            user: user,
            eventType: eventType,
            event: event
        )
    }

    static func remoteConfig(
        user: HackleUser,
        evaluation: RemoteConfigEvaluation,
        properties: [String: Any],
        internalProperties: [String: Any],
        timestamp: Date
    ) -> UserEvents.RemoteConfig {
        RemoteConfig(
            insertId: UUID().uuidString.lowercased(),
            timestamp: timestamp,
            user: user,
            parameter: evaluation.parameter,
            valueId: evaluation.valueId,
            decisionReason: evaluation.reason,
            properties: properties,
            internalProperties: internalProperties
        )
    }

    struct Exposure: UserEvent {
        let type: UserEventType = .exposure
        let insertId: String
        let timestamp: Date
        let user: HackleUser
        let experiment: Experiment
        let variationId: Variation.Id?
        let variationKey: Variation.Key
        let decisionReason: String
        let properties: [String: Any]
        let internalProperties: [String: Any]

        init(insertId: String, timestamp: Date, user: HackleUser, experiment: Experiment, variationId: Variation.Id?, variationKey: Variation.Key, decisionReason: String, properties: [String: Any], internalProperties: [String: Any]) {
            self.insertId = insertId
            self.timestamp = timestamp
            self.user = user
            self.experiment = experiment
            self.variationId = variationId
            self.variationKey = variationKey
            self.decisionReason = decisionReason
            self.properties = properties
            self.internalProperties = internalProperties
        }

        func with(user: HackleUser) -> UserEvent {
            Exposure(
                insertId: insertId,
                timestamp: timestamp,
                user: user,
                experiment: experiment,
                variationId: variationId,
                variationKey: variationKey,
                decisionReason: decisionReason,
                properties: properties,
                internalProperties: internalProperties
            )
        }
    }

    struct Track: UserEvent {
        let type: UserEventType = .track
        let insertId: String
        let timestamp: Date
        let user: HackleUser
        let eventType: EventType
        let event: Event

        init(insertId: String, timestamp: Date, user: HackleUser, eventType: EventType, event: Event) {
            self.insertId = insertId
            self.timestamp = timestamp
            self.user = user
            self.eventType = eventType
            self.event = event
        }

        func with(user: HackleUser) -> UserEvent {
            Track(
                insertId: insertId,
                timestamp: timestamp,
                user: user,
                eventType: eventType,
                event: event
            )
        }
    }

    struct RemoteConfig: UserEvent {
        let type: UserEventType = .remoteConfig
        let insertId: String
        let timestamp: Date
        let user: HackleUser
        let parameter: RemoteConfigParameter
        let valueId: Int64?
        let decisionReason: String
        let properties: [String: Any]
        let internalProperties: [String: Any]

        init(insertId: String, timestamp: Date, user: HackleUser, parameter: RemoteConfigParameter, valueId: Int64?, decisionReason: String, properties: [String: Any], internalProperties: [String: Any]) {
            self.insertId = insertId
            self.timestamp = timestamp
            self.user = user
            self.parameter = parameter
            self.valueId = valueId
            self.decisionReason = decisionReason
            self.properties = properties
            self.internalProperties = internalProperties
        }

        func with(user: HackleUser) -> UserEvent {
            RemoteConfig(
                insertId: insertId,
                timestamp: timestamp,
                user: user,
                parameter: parameter,
                valueId: valueId,
                decisionReason: decisionReason,
                properties: properties,
                internalProperties: internalProperties
            )
        }
    }
}
