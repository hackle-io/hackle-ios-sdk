//
//  MockInAppMessageEventTracker.swift
//  HackleTests
//
//  Created by yong on 2023/07/18.
//

import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageEventTracker: Mock, InAppMessageEventTracker {

    lazy var trackMock = MockFunction(self, track)

    func track(context: InAppMessagePresentationContext, event: InAppMessage.Event, timestamp: Date) {
        call(trackMock, args: (context, event, timestamp))
    }
}