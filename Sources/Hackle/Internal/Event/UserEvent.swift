//
// Created by yong on 2020/12/11.
//

import Foundation

protocol UserEvent {
    var type: UserEventType { get }
    var timestamp: Date { get }
    var user: HackleUser { get }
}

enum UserEventType: Int {
    case exposure = 0
    case track = 1
}

enum UserEvents {

    static func exposure(experiment: Experiment, user: HackleUser, evaluation: Evaluation) -> UserEvent {
        Exposure(
            insertId: UUID().uuidString.lowercased(),
            timestamp: Date(),
            user: user,
            experiment: experiment,
            variationId: evaluation.variationId,
            variationKey: evaluation.variationKey,
            decisionReason: evaluation.reason,
            properties: exposureProperties(evaluation: evaluation)
        )
    }

    private static func exposureProperties(evaluation: Evaluation) -> [String: Any] {
        guard let config = evaluation.config else {
            return [:]
        }

        return ["$parameterConfigurationId": config.id]
    }

    static func track(user: HackleUser, eventType: EventType, event: Event) -> UserEvent {
        Track(
            insertId: UUID().uuidString.lowercased(),
            timestamp: Date(),
            user: user,
            eventType: eventType,
            event: event
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

        init(insertId: String, timestamp: Date, user: HackleUser, experiment: Experiment, variationId: Variation.Id?, variationKey: Variation.Key, decisionReason: String, properties: [String: Any]) {
            self.insertId = insertId
            self.timestamp = timestamp
            self.user = user
            self.experiment = experiment
            self.variationId = variationId
            self.variationKey = variationKey
            self.decisionReason = decisionReason
            self.properties = properties
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
    }
}
