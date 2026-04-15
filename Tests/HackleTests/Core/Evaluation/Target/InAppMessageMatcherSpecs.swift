//
//  InAppMessageMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class InAppMessageUserOverrideMatcherSpecs: QuickSpec {
    override class func spec() {

        var sut: InAppMessageUserOverrideMatcher!

        beforeEach {
            sut = InAppMessageUserOverrideMatcher()
        }

        it("when override info is empty then returns false") {
            // given
            let inAppMessage = InAppMessage.create()
            let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == false
        }

        it("overridden") {
            // given
            let user = HackleUser.builder().identifier(.user, "a").build()
            let inAppMessage = InAppMessage.create(
                targetContext: InAppMessage.targetContext(overrides: [
                    InAppMessage.UserOverride(identifierType: "$id", identifiers: ["a"]),
                    InAppMessage.UserOverride(identifierType: "$userId", identifiers: ["a"])
                ])
            )
            let request = InAppMessage.eligibilityRequest(user: user, inAppMessage: inAppMessage)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == true
        }

        it("not overridden") {
            // given
            let user = HackleUser.builder().identifier(.device, "a").build()
            let inAppMessage = InAppMessage.create(
                targetContext: InAppMessage.targetContext(overrides: [
                    InAppMessage.UserOverride(identifierType: "$id", identifiers: ["a"]),
                    InAppMessage.UserOverride(identifierType: "$userId", identifiers: ["a"])
                ])
            )
            let request = InAppMessage.eligibilityRequest(user: user, inAppMessage: inAppMessage)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == false
        }
    }
}

class InAppMessageTargetMatcherSpecs: QuickSpec {
    override class func spec() {

        it("when targets is empty when returns true") {
            // given
            let sut = InAppMessageTargetMatcher(targetMatcher: TargetMatcherStub.of())
            let request = InAppMessage.eligibilityRequest()

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == true
        }

        it("when any matches then returns true") {
            // given
            let targetMatcher = TargetMatcherStub.of(false, false, false, true, false)
            let sut = InAppMessageTargetMatcher(targetMatcher: targetMatcher)
            let request = InAppMessage.eligibilityRequest(
                inAppMessage: InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: self.targets()))
            )
            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == true
            expect(targetMatcher.callCount) == 4
        }

        it("when all do not match then returns false") {
            // given
            let targetMatcher = TargetMatcherStub.of(false, false, false, false, false)
            let sut = InAppMessageTargetMatcher(targetMatcher: targetMatcher)
            let request = InAppMessage.eligibilityRequest(
                inAppMessage: InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: self.targets()))
            )
            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == false
            expect(targetMatcher.callCount) == 5
        }
    }

    private func targets() -> [Target] {
        [
            Target(conditions: [condition()]),
            Target(conditions: [condition()]),
            Target(conditions: [condition()]),
            Target(conditions: [condition()]),
            Target(conditions: [condition()])
        ]
    }

    private func condition() -> Target.Condition {
        Target.Condition(key: Target.Key(type: .userProperty, name: "age"), match: Target.Match(type: .match, matchOperator: ._in, valueType: .number, values: [HackleValue(value: 1)]))
    }
}


class InAppMessageHiddenMatcherSpecs: QuickSpec {
    override class func spec() {
        var storage: InAppMessageHiddenStorage!
        var sut: InAppMessageHiddenMatcher!

        beforeEach {
            storage = DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
            sut = InAppMessageHiddenMatcher(storage: storage)
        }

        it("match") {
            // given
            let inAppMessage = InAppMessage.create(id: 42)
            let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

            storage.put(inAppMessage: inAppMessage, expireAt: Date() + 10)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == true
        }

        it("not match") {
            // given
            let inAppMessage = InAppMessage.create(id: 42)
            let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == false
        }
    }
}


class InAppMessageFrequencyCapMatcherSpecs: QuickSpec {
    override class func spec() {
        var storage: InAppMessageImpressionStorage!
        var sut: InAppMessageFrequencyCapMatcher!
        var user: HackleUser!
        var now: Date!

        beforeEach {
            storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
            sut = InAppMessageFrequencyCapMatcher(storage: storage)
            user = HackleUser.builder().identifier(.id, "user1").build()
            now = Date()
        }

        context("frequencyCap이 nil일 때") {
            it("false를 반환한다") {
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger())
                let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage)

                let result = try? sut.matches(request: request, context: Evaluators.context())
                expect(result) == false
            }
        }

        context("frequencyCap이 설정된 경우") {
            it("impression이 identifierCap 조건을 만족하면 true") {
                let identifierCap = InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 1)
                let frequencyCap = InAppMessage.EventTrigger.FrequencyCap(identifierCaps: [identifierCap], durationCap: nil)
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger(rules: [], frequencyCap: frequencyCap))
                

                let impression = InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970)
                try storage.set(inAppMessage: inAppMessage, impressions: [impression])
                
                let request = InAppMessage.eligibilityRequest(user: user, inAppMessage: inAppMessage)

                let result = try? sut.matches(request: request, context: Evaluators.context())
                expect(result) == true
            }

            it("impression이 identifierCap 조건을 만족하지 않으면 false") {
                let identifierCap = InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 1)
                let frequencyCap = InAppMessage.EventTrigger.FrequencyCap(identifierCaps: [identifierCap], durationCap: nil)
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger(rules: [], frequencyCap: frequencyCap))
                user = HackleUser.builder().identifier(.id, "user1").build()
                
                let impression = InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970)
                try storage.set(inAppMessage: inAppMessage, impressions: [impression])

                user = HackleUser.builder().identifier(.id, "user2").build()
                let request = InAppMessage.eligibilityRequest(user: user, inAppMessage: inAppMessage)

                let result = try? sut.matches(request: request, context: Evaluators.context())
                expect(result) == false
            }

            it("durationCap이 만족하면 true") {
                let durationCap = InAppMessage.EventTrigger.DurationCap(duration: 60, count: 1)
                let frequencyCap = InAppMessage.EventTrigger.FrequencyCap(identifierCaps: [], durationCap: durationCap)
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger(rules: [], frequencyCap: frequencyCap))

                let impression = InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970 - 30)
                try storage.set(inAppMessage: inAppMessage, impressions: [impression])

                let request = InAppMessage.eligibilityRequest(user: user, inAppMessage: inAppMessage)

                let result = try? sut.matches(request: request, context: Evaluators.context())
                expect(result) == true
            }

            it("durationCap이 만족하지 않으면 false") {
                let durationCap = InAppMessage.EventTrigger.DurationCap(duration: 60, count: 1)
                let frequencyCap = InAppMessage.EventTrigger.FrequencyCap(identifierCaps: [], durationCap: durationCap)
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger(rules: [], frequencyCap: frequencyCap))

                let impression = InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970 - 120)
                try storage.set(inAppMessage: inAppMessage, impressions: [impression])

                let request = InAppMessage.eligibilityRequest(user: user, inAppMessage: inAppMessage)

                let result = try? sut.matches(request: request, context: Evaluators.context())
                expect(result) == false
            }
        }
    }
}
