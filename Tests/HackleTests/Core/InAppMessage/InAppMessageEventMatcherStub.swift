//
//  InAppMessageEventMatcherStub.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
@testable import Hackle

class InAppMessageEventMatcherStub: InAppMessageEventMatcher {

    var isMatches: [Bool] {
        didSet {
            callCount = 0
        }
    }
    var callCount = 0

    init(isMatches: [Bool] = []) {
        self.isMatches = isMatches
    }

    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvent) throws -> Bool {
        let isMatch = isMatches[callCount]
        callCount += 1
        return isMatch
    }
}
