//
// Created by yong on 2020/12/20.
//

import Foundation
@testable import Hackle

class MockUserEvent: UserEvent {
    var type: UserEventType
    var user: HackleUser
    var timestamp: Date

    init(user: HackleUser, timestamp: Date = Date(), type: UserEventType = .exposure) {
        self.type = type
        self.user = user
        self.timestamp = timestamp
    }

    func with(user: HackleUser) -> UserEvent {
        MockUserEvent(user: user, timestamp: timestamp, type: type)
    }
}
