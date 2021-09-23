//
// Created by yong on 2020/12/11.
//

import Foundation

protocol UserEvent {
    var timestamp: Date { get }
    var user: User { get }
}

enum UserEvents {

    static func exposure(experiment: Experiment, user: User, evaluation: Evaluation) -> UserEvent {
        Exposure(
            timestamp: Date(),
            user: user,
            experiment: experiment,
            variationId: evaluation.variationId,
            variationKey: evaluation.variationKey,
            decisionReason: evaluation.reason
        )
    }

    static func track(user: User, eventType: EventType, event: Event) -> UserEvent {
        Track(
            timestamp: Date(),
            user: user,
            eventType: eventType,
            event: event
        )
    }

    struct Exposure: UserEvent {
        let timestamp: Date
        let user: User
        let experiment: Experiment
        let variationId: Variation.Id?
        let variationKey: Variation.Key
        let decisionReason: String

        init(timestamp: Date, user: User, experiment: Experiment, variationId: Variation.Id?, variationKey: Variation.Key, decisionReason: String) {
            self.timestamp = timestamp
            self.user = user
            self.experiment = experiment
            self.variationId = variationId
            self.variationKey = variationKey
            self.decisionReason = decisionReason
        }
    }

    struct Track: UserEvent {
        let timestamp: Date
        let user: User
        let eventType: EventType
        let event: Event

        init(timestamp: Date, user: User, eventType: EventType, event: Event) {
            self.timestamp = timestamp
            self.user = user
            self.eventType = eventType
            self.event = event
        }
    }
}
