//
//  InAppMessageUserOverrideMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class InAppMessageUserOverrideMatcherSpecs: QuickSpec {
    override func spec() {

        var sut: InAppMessageUserOverrideMatcher!

        beforeEach {
            sut = InAppMessageUserOverrideMatcher()
        }

        it("when override info is empty then returns false") {
            // given
            let inAppMessage = InAppMessage.create()
            let request = InAppMessage.request(inAppMessage: inAppMessage)

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
            let request = InAppMessage.request(user: user, inAppMessage: inAppMessage)

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
            let request = InAppMessage.request(user: user, inAppMessage: inAppMessage)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == false
        }
    }
}

class InAppMessageTargetMatcherSpecs: QuickSpec {
    override func spec() {

        it("when targets is empty when returns true") {
            // given
            let sut = InAppMessageTargetMatcher(targetMatcher: TargetMatcherStub.of())
            let request = InAppMessage.request()

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == true
        }

        it("when any matches then returns true") {
            // given
            let targetMatcher = TargetMatcherStub.of(false, false, false, true, false)
            let sut = InAppMessageTargetMatcher(targetMatcher: targetMatcher)
            let request = InAppMessage.request(
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
            let request = InAppMessage.request(
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
    override func spec() {
        var storage: InAppMessageHiddenStorage!
        var sut: InAppMessageHiddenMatcher!

        beforeEach {
            storage = DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
            sut = InAppMessageHiddenMatcher(storage: storage)
        }

        it("match") {
            // given
            let inAppMessage = InAppMessage.create(id: 42)
            let request = InAppMessage.request(inAppMessage: inAppMessage)

            storage.put(inAppMessage: inAppMessage, expireAt: Date() + 10)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == true
        }

        it("not match") {
            // given
            let inAppMessage = InAppMessage.create(id: 42)
            let request = InAppMessage.request(inAppMessage: inAppMessage)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context())

            // then
            expect(actual) == false
        }
    }
}
