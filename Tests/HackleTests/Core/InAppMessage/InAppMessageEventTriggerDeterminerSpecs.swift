import Foundation
import Quick
import Nimble
@testable import Hackle


class InAppMessageEventTriggerDeterminerSpecs: QuickSpec {
    override func spec() {
        describe("InAppMessageEventTriggerRuleDeterminer") {
            var targetMatcher: TargetMatcherStub!
            var sut: InAppMessageEventTriggerRuleDeterminer!
            var workspace: MockWorkspace!

            beforeEach {
                targetMatcher = TargetMatcherStub()
                sut = InAppMessageEventTriggerRuleDeterminer(targetMatcher: targetMatcher)
                workspace = MockWorkspace()
            }

            it("when trigger rule is empty then returns false") {
                // given
                let event = UserEvents.track("test")
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(rules: []))

                // when
                let actual = try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)

                // then
                expect(actual) == false
            }

            it("when all trigger rules do not match then returns false") {
                // given
                let event = UserEvents.track("test")
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(rules: [
                    InAppMessage.EventTrigger.Rule(eventKey: "not_match", targets: []),
                    InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                    InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition(), Target.condition())]),
                ]))
                targetMatcher.isMatches = [false, false]

                // when
                let actual = try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)

                // then
                expect(actual) == false
                expect(targetMatcher.callCount) == 2
            }

            it("when trigger rule matched then returns true") {
                // given
                let event = UserEvents.track("test")
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(rules: [
                    InAppMessage.EventTrigger.Rule(eventKey: "not_match", targets: []),
                    InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                    InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                    InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                    InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                ]))
                targetMatcher.isMatches = [false, false, true, false]

                // when
                let actual = try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)

                // then
                expect(actual) == true
                expect(targetMatcher.callCount) == 3
            }
        }

        describe("InAppMessageEventTriggerFrequencyCapDeterminer") {

            var storage: InAppMessageImpressionStorage!
            var sut: InAppMessageEventTriggerFrequencyCapDeterminer!
            var workspace: Workspace!

            beforeEach {
                storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
                sut = InAppMessageEventTriggerFrequencyCapDeterminer(storage: storage)
                workspace = MockWorkspace()
            }

            it("when frequencyCap is null then returns true") {
                // given
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(frequencyCap: nil))
                let event = UserEvents.track("test")

                // when
                let actual = try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)

                // then
                expect(actual) == true
            }

            it("when frequencyCap is empty then returns true") {
                // given
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(
                    frequencyCap: InAppMessage.frequencyCap(
                        identifierCaps: [],
                        durationCap: nil
                    )
                ))
                let event = UserEvents.track("test")

                // when
                let actual = try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)

                // then
                expect(actual) == true
            }

            it("identifier cap") {
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(
                    frequencyCap: InAppMessage.frequencyCap(
                        identifierCaps: [InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 3)],
                        durationCap: nil
                    )
                ))
                let user = HackleUser.of(userId: "user")
                let event = UserEvents.track("test", user: user)

                try storage.set(inAppMessage: inAppMessage, impressions: [
                    impression(user, 1),
                    impression(user, 2),
                ])
                expect(try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)) == true

                try storage.set(inAppMessage: inAppMessage, impressions: [
                    impression(user, 1),
                    impression(user, 2),
                    impression(user, 3),
                ])
                expect(try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)) == false
            }

            it("duration cap") {
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(
                    frequencyCap: InAppMessage.frequencyCap(
                        identifierCaps: [],
                        durationCap: InAppMessage.EventTrigger.DurationCap(duration: 10, count: 3)
                    )
                ))
                let user = HackleUser.of(userId: "user")
                let event = UserEvents.track("test", user: user, timestamp: 50)

                try storage.set(inAppMessage: inAppMessage, impressions: [
                    impression(user, 40),
                    impression(user, 41),
                    impression(user, 42)
                ])
                expect(try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)) == false

                try storage.set(inAppMessage: inAppMessage, impressions: [
                    impression(user, 39),
                    impression(user, 40),
                    impression(user, 41)
                ])
                expect(try sut.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: event)) == true
            }


            func impression(_ user: HackleUser, _ timestamp: Double) -> InAppMessageImpression {
                InAppMessageImpression(identifiers: user.identifiers, timestamp: timestamp)
            }
        }

        describe("FrequencyCapPredicate") {
            describe("IdentifierCap") {

                it("when user identifier is nil then false") {
                    let cap = InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 42)

                    let event = UserEvents.track("test", user: HackleUser.builder().identifier("$deviceId", "a").build())
                    let impression = InAppMessageImpression(identifiers: ["$id": "a"], timestamp: 42)

                    expect(cap.matches(event: event, impression: impression)) == false
                }

                it("when impression identifier is nil then false") {
                    let cap = InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 42)

                    let event = UserEvents.track("test", user: HackleUser.builder().identifier("$id", "a").build())
                    let impression = InAppMessageImpression(identifiers: ["$deviceId": "a"], timestamp: 42)

                    expect(cap.matches(event: event, impression: impression)) == false
                }

                it("not matches") {
                    let cap = InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 42)

                    let event = UserEvents.track("test", user: HackleUser.builder().identifier("$id", "a").build())
                    let impression = InAppMessageImpression(identifiers: ["$id": "b"], timestamp: 42)

                    expect(cap.matches(event: event, impression: impression)) == false
                }

                it("matches") {
                    let cap = InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 42)

                    let event = UserEvents.track("test", user: HackleUser.builder().identifier("$id", "a").build())
                    let impression = InAppMessageImpression(identifiers: ["$id": "a"], timestamp: 42)

                    expect(cap.matches(event: event, impression: impression)) == true
                }
            }

            describe("DurationCap") {
                it("matches") {
                    let cap = InAppMessage.EventTrigger.DurationCap(duration: 100, count: 320)

                    func assert(_ event: Double, _ impression: Double, _ result: Bool) {
                        let event = UserEvents.track("test", timestamp: event)
                        let impression = InAppMessageImpression(identifiers: ["$id": "a"], timestamp: impression)

                        expect(cap.matches(event: event, impression: impression)) == result
                    }

                    assert(200, 100, true)
                    assert(200, 99, false)
                }
            }
        }
    }
}
