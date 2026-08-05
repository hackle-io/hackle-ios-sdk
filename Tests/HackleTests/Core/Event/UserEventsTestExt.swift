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
        timestamp: Double = Date().timeIntervalSince1970,
        workspace: Workspace? = nil
    ) -> UserEvents.Track {
        UserEvents.track(
            event: Event.builder(eventKey).properties(properties).build(),
            workspace: workspace,
            timestamp: Date(timeIntervalSince1970: timestamp),
            user: user
        )
    }

    static func exposure(workspace: Workspace = MockWorkspace()) -> UserEvents.Exposure {
        UserEvents.exposure(
            user: HackleUser.builder().identifier(.id, "user").build(),
            workspace: workspace,
            evaluation: experimentEvaluation(),
            properties: [:],
            timestamp: Date()
        )
    }
}