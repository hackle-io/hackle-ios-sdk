//
// Created by yong on 2020/12/20.
//

import Foundation
@testable import Hackle

class MockUserEvent: UserEvent {
    var user: HackleUser
    var timestamp: Date

    init(user: HackleUser, timestamp: Date = Date()) {
        self.user = user
        self.timestamp = timestamp
    }
}
