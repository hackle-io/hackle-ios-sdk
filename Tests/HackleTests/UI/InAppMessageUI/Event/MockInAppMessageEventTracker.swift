//
//  MockInAppMessageEventTracker.swift
//  HackleTests
//
//  Created by yong on 2023/07/18.
//

import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageEventTracker: Mock, InAppMessageEventTracker {

    lazy var trackMock = MockFunction(self, track)

    func track(context: InAppMessageContext, event: InAppMessage.Event, user: HackleUser, timestamp: Date) {
        call(trackMock, args: (context, event, user, timestamp))
    }
}