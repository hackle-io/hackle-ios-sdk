//
//  DefaultInAppMessageEventMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultInAppMessageEventMatcherSpecs: QuickSpec {
    override func spec() {

        var ruleDeterminer: MockInAppMessageEventTriggerDeterminer!
        var sut: DefaultInAppMessageEventMatcher!
        var workspace: MockWorkspace!

        beforeEach {
            ruleDeterminer = MockInAppMessageEventTriggerDeterminer(isMatch: false)
            sut = DefaultInAppMessageEventMatcher(ruleDeterminer: ruleDeterminer)
            workspace = MockWorkspace()
        }

        it("when event is not TrackEvent then returns false") {
            // given
            let exposureEvent = UserEvents.exposure()
            let inAppMessage = InAppMessage.create()

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: exposureEvent)

            // then
            expect(actual) == false
        }

        it("not trigger target - rule") {
            // given
            let event = UserEvents.track("test")
            let inAppMessage = InAppMessage.create()
            ruleDeterminer.isMatch = false

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

            // then
            expect(actual) == false
        }
    }
}
