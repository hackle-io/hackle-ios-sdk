//
// Created by yong on 2020/12/11.
//

import Foundation

protocol UserEvent {
    var user: User { get }
    var timestamp: Date { get }
}

enum UserEvents {

    static func exposure(user: User, experiment: Experiment, variation: Variation) -> Exposure {
        Exposure(
            user: user,
            timestamp: Date(),
            experiment: experiment,
            variation: variation
        )
    }

    static func track(user: User, eventType: EventType, event: Event) -> Track {
        Track(
            user: user,
            timestamp: Date(),
            eventType: eventType,
            event: event
        )
    }

    struct Exposure: UserEvent {
        let user: User
        let timestamp: Date
        let experiment: Experiment
        let variation: Variation

        init(user: User, timestamp: Date, experiment: Experiment, variation: Variation) {
            self.user = user
            self.timestamp = timestamp
            self.experiment = experiment
            self.variation = variation
        }
    }

    struct Track: UserEvent {
        let user: User
        let timestamp: Date
        let eventType: EventType
        let event: Event

        init(user: User, timestamp: Date, eventType: EventType, event: Event) {
            self.user = user
            self.timestamp = timestamp
            self.eventType = eventType
            self.event = event
        }
    }
}
