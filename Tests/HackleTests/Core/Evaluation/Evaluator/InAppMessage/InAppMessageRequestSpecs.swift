//
//  InAppMessageRequestSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageRequestSpecs: QuickSpec {
    override func spec() {

        it("==") {

            let workspace = MockWorkspace()
            let user = HackleUser.builder().identifier(.id, "user").build()

            let request1 = InAppMessageRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(key: 1), timestamp: Date())
            let request1_ = InAppMessageRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(key: 1), timestamp: Date())
            let request2 = InAppMessageRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(key: 2), timestamp: Date())

            expect(request1) == request1_
            expect(request1) != request2
        }
    }
}