//
//  DefaultInAppMessageDeterminerSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultInAppMessageDeterminerSpecs: QuickSpec {
    override func spec() {
        var workspaceFetcher: MockWorkspaceFetcher!
        var inAppMessageEventMatcher: InAppMessageEventMatcherStub!
        var core: HackleCoreStub!
        var sut: DefaultInAppMessageDeterminer!

        beforeEach {
            workspaceFetcher = MockWorkspaceFetcher()
            inAppMessageEventMatcher = InAppMessageEventMatcherStub()
            core = HackleCoreStub()
            sut = DefaultInAppMessageDeterminer(workspaceFetcher: workspaceFetcher, eventMatcher: inAppMessageEventMatcher, core: core)
        }

        it("workspace 가 없으면 nil 리턴") {
            // given
            every(workspaceFetcher.fetchMock).returns(nil)
            let event = UserEvents.track("test")

            // when
            let actual = try sut.determineOrNull(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("InAppMessage 가 없으면 nil 리턴") {
            // given
            let workspace = MockWorkspace()
            every(workspaceFetcher.fetchMock).returns(workspace)
            let event = UserEvents.track("test")

            // when
            let actual = try sut.determineOrNull(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("일치하는 InAppMessage 가 하나도 없으면 nil 리턴") {
            // given
            determine(
                decision(false),
                decision(true, nil),
                decision(true, .create(), nil)
            )

            let event = UserEvents.track("test")

            // when
            let actual = try sut.determineOrNull(event: event)

            // then
            expect(actual).to(beNil())
            expect(inAppMessageEventMatcher.callCount) == 3
            expect(core.inAppMessageCount) == 2
        }

        it("일치하는 InAppMessage 가 있는 경우") {
            // given
            let message = InAppMessage.message()
            let iam = InAppMessage.create(id: 42, messageContext: InAppMessage.messageContext(messages: [message]))

            determine(
                decision(true),
                decision(true, nil),
                decision(true, .create(), nil),
                decision(true, iam, message, DecisionReason.IN_APP_MESSAGE_TARGET, ["a": 42]),
                decision(false)
            )
            let event = UserEvents.track("test")

            // when
            let actual = try sut.determineOrNull(event: event)

            // then
            expect(actual).toNot(beNil())
            expect(actual?.inAppMessage).to(beIdenticalTo(iam))
            expect(actual?.message).to(beIdenticalTo(message))
            expect(actual?.properties["decision_reason"] as? String) == DecisionReason.IN_APP_MESSAGE_TARGET
            expect(actual?.properties["trigger_event_insert_id"] as? String) == event.insertId
            expect(actual?.properties["a"] as? Int) == 42
            expect(inAppMessageEventMatcher.callCount) == 4
            expect(core.inAppMessageCount) == 4
        }

        func determine(_ decisions: Decision...) {
            inAppMessageEventMatcher.isMatches = decisions.map {
                $0.isEventMatches
            }
            core.inAppMessageDecisions = decisions.map {
                $0.decision
            }

            let iam = InAppMessage.create()
            let workspace = MockWorkspace(inAppMessages: decisions.map { _ in
                iam
            })
            every(workspace.getInAppMessageOrNilMock).returns(iam)
            every(workspaceFetcher.fetchMock).returns(workspace)
        }

        func decision(
            _ isMatch: Bool,
            _ inAppMessage: InAppMessage? = nil,
            _ message: InAppMessage.Message? = nil,
            _ reason: String = DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET,
            _ properties: [String: Any] = [:]
        ) -> Decision {
            Decision(isEventMatches: isMatch, decision: InAppMessageDecision.of(inAppMessage: inAppMessage, message: message, reason: reason, properties: properties))
        }

        struct Decision {
            var isEventMatches: Bool
            var decision: InAppMessageDecision
        }
    }
}
