//
// Created by yong on 2020/12/20.
//

import Foundation
@testable import Hackle

class MockUserEvent: UserEvent {
    var insertId: String
    var type: UserEventType
    var user: HackleUser
    var timestamp: Date
    var internalProperties: [String : Any]

    init(
        insertId: String = UUID().uuidString.lowercased(),
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        timestamp: Date = Date(),
        type: UserEventType = .exposure,
        internalProperties: [String: Any] = [:]
    ) {
        self.insertId = insertId
        self.type = type
        self.user = user
        self.timestamp = timestamp
        self.internalProperties = internalProperties
    }

    func with(user: HackleUser) -> UserEvent {
        MockUserEvent(user: user, timestamp: timestamp, type: type)
    }
}
