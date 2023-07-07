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

        var targetMatcher: TargetMatcherStub!
        var sut: DefaultInAppMessageEventMatcher!
        var workspace: MockWorkspace!

        beforeEach {
            targetMatcher = TargetMatcherStub()
            sut = DefaultInAppMessageEventMatcher(targetMatcher: targetMatcher)
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

        it("when trigger rule is empty then returns false") {
            // given
            let event = UserEvents.track("test")
            let inAppMessage = InAppMessage.create(triggerRules: [])

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

            // then
            expect(actual) == false
        }

        it("when all trigger rules do not match then returns false") {
            // given
            let event = UserEvents.track("test")
            let inAppMessage = InAppMessage.create(triggerRules: [
                InAppMessage.TriggerRule(eventKey: "not_match", targets: []),
                InAppMessage.TriggerRule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.TriggerRule(eventKey: "test", targets: [.create(Target.condition(), Target.condition())]),
            ])
            targetMatcher.isMatches = [false, false]

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

            // then
            expect(actual) == false
            expect(targetMatcher.callCount) == 2
        }

        it("when trigger rule matched then returns true") {
            // given
            let event = UserEvents.track("test")
            let inAppMessage = InAppMessage.create(triggerRules: [
                InAppMessage.TriggerRule(eventKey: "not_match", targets: []),
                InAppMessage.TriggerRule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.TriggerRule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.TriggerRule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.TriggerRule(eventKey: "test", targets: [.create(Target.condition())]),
            ])
            targetMatcher.isMatches = [false, false, true, false]

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

            // then
            expect(actual) == true
            expect(targetMatcher.callCount) == 3
        }
    }
}
