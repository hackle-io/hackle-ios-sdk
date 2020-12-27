//
// Created by yong on 2020/12/20.
//

import Foundation
@testable import Hackle

class MockUserEvent: UserEvent {
    var user: User
    var timestamp: Date

    init(user: User, timestamp: Date = Date()) {
        self.user = user
        self.timestamp = timestamp
    }
}
