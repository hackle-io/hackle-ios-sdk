//
//  UserEventsTestExt.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
@testable import Hackle

extension UserEvents {

    static func track(
        _ eventKey: String,
        properties: [String: Any] = [:],
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        timestamp: Double = Date().timeIntervalSince1970
    ) -> UserEvents.Track {
        UserEvents.track(
            eventType: EventTypeEntity(id: 1, key: eventKey),
            event: Event.builder(eventKey).properties(properties).build(),
            timestamp: Date(timeIntervalSince1970: timestamp),
            user: user
        )
    }

    static func exposure() -> UserEvents.Exposure {
        UserEvents.exposure(
            user: HackleUser.builder().identifier(.id, "user").build(),
            evaluation: experimentEvaluation(),
            properties: [:],
            internalProperties: [:],
            timestamp: Date()
        )
    }
}
