import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageDebugInspectorSpecs: QuickSpec {
    override class func spec() {

        func inspector() -> InAppMessageDebugInspector {
            InAppMessageDebugInspector(
                impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()),
                valueOperatorMatcher: DefaultValueOperatorMatcher(
                    valueMatcherFactory: ValueMatcherFactory(),
                    operatorMatcherFactory: OperatorMatcherFactory()
                ),
                userValueResolver: DefaultUserValueResolver()
            )
        }

        func inspector(impressionStorage: InAppMessageImpressionStorage) -> InAppMessageDebugInspector {
            InAppMessageDebugInspector(
                impressionStorage: impressionStorage,
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()),
                valueOperatorMatcher: DefaultValueOperatorMatcher(
                    valueMatcherFactory: ValueMatcherFactory(),
                    operatorMatcherFactory: OperatorMatcherFactory()
                ),
                userValueResolver: DefaultUserValueResolver()
            )
        }

        describe("targetDetails") {
            it("user property 조건 - 매칭되면 isMatched=true, 유저 값 노출") {
                let user = HackleUser.builder().property("age", 25).build()
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let groups = inspector().targetDetails(inAppMessage: inAppMessage, user: user)

                expect(groups.count) == 1
                expect(groups[0].index) == 1
                expect(groups[0].conditions.count) == 1
                let c = groups[0].conditions[0]
                expect(c.keyType) == "USER_PROPERTY"
                expect(c.keyName) == "age"
                expect(c.isUserProperty) == true
                expect(c.isMatched) == true
                expect(c.userValue) == "25"
            }

            it("user property 조건 - 비매칭되면 isMatched=false") {
                let user = HackleUser.builder().property("age", 15).build()
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let c = inspector().targetDetails(inAppMessage: inAppMessage, user: user)[0].conditions[0]

                expect(c.isMatched) == false
            }

            it("user property 값이 없으면 userValue=nil, isMatched=false") {
                let user = HackleUser.builder().build()
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let c = inspector().targetDetails(inAppMessage: inAppMessage, user: user)[0].conditions[0]

                expect(c.userValue).to(beNil())
                expect(c.isMatched) == false
            }

            it("user property가 아닌 조건(SEGMENT)은 userValue/isMatched가 nil") {
                let user = HackleUser.builder().build()
                let condition = Target.Condition(
                    key: Target.Key(type: .segment, name: "seg1"),
                    match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "x")])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [Target(conditions: [condition])])
                )

                let c = inspector().targetDetails(inAppMessage: inAppMessage, user: user)[0].conditions[0]

                expect(c.keyType) == "SEGMENT"
                expect(c.isUserProperty) == false
                expect(c.userValue).to(beNil())
                expect(c.isMatched).to(beNil())
            }

            it("targets가 여러 개면 그룹 index가 1부터 증가") {
                let condition = Target.Condition(
                    key: Target.Key(type: .userProperty, name: "age"),
                    match: Target.Match(type: .match, matchOperator: .gte, valueType: .number, values: [HackleValue(value: 20)])
                )
                let inAppMessage = InAppMessage.create(
                    targetContext: InAppMessage.targetContext(targets: [
                        Target(conditions: [condition]),
                        Target(conditions: [condition])
                    ])
                )

                let groups = inspector().targetDetails(inAppMessage: inAppMessage, user: HackleUser.builder().build())

                expect(groups.map { $0.index }) == [1, 2]
            }
        }

        describe("frequencyDetail") {
            it("identifierCap - 한도와 현재 카운트를 계산한다") {
                let storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
                let user = HackleUser.builder().identifier(.id, "user1").build()
                let identifierCap = InAppMessage.EventTrigger.IdentifierCap(identifierType: "$id", count: 3)
                let frequencyCap = InAppMessage.EventTrigger.FrequencyCap(identifierCaps: [identifierCap], durationCap: nil)
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger(rules: [], frequencyCap: frequencyCap))
                let now = Date()
                try storage.set(inAppMessage: inAppMessage, impressions: [
                    InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970),
                    InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970)
                ])

                let detail = inspector(impressionStorage: storage).frequencyDetail(inAppMessage: inAppMessage, user: user, now: now)

                expect(detail.caps.count) == 1
                expect(detail.caps[0].threshold) == 3
                expect(detail.caps[0].currentCount) == 2
                expect(detail.caps[0].isExceeded) == false
                expect(detail.impressions.count) == 2
            }

            it("durationCap - 기간 내 노출만 카운트하고 초과 여부를 표시한다") {
                let storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
                let user = HackleUser.builder().identifier(.id, "user1").build()
                let durationCap = InAppMessage.EventTrigger.DurationCap(duration: 60, count: 1)
                let frequencyCap = InAppMessage.EventTrigger.FrequencyCap(identifierCaps: [], durationCap: durationCap)
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger(rules: [], frequencyCap: frequencyCap))
                let now = Date()
                try storage.set(inAppMessage: inAppMessage, impressions: [
                    InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970 - 30),  // 기간 내
                    InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970 - 120)  // 기간 밖
                ])

                let detail = inspector(impressionStorage: storage).frequencyDetail(inAppMessage: inAppMessage, user: user, now: now)

                expect(detail.caps.count) == 1
                expect(detail.caps[0].currentCount) == 1
                expect(detail.caps[0].isExceeded) == true
            }

            it("frequencyCap이 nil이면 caps는 비어있고 impressions만 노출") {
                let storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
                let user = HackleUser.builder().identifier(.id, "user1").build()
                let inAppMessage = InAppMessage.create(id: 42, eventTrigger: InAppMessage.eventTrigger())
                let now = Date()
                try storage.set(inAppMessage: inAppMessage, impressions: [
                    InAppMessageImpression(identifiers: user.identifiers, timestamp: now.timeIntervalSince1970)
                ])

                let detail = inspector(impressionStorage: storage).frequencyDetail(inAppMessage: inAppMessage, user: user, now: now)

                expect(detail.caps.count) == 0
                expect(detail.impressions.count) == 1
            }
        }

        describe("inspect") {
            it("TARGET reason이면 .target을 반환") {
                let inAppMessage = InAppMessage.create()
                let detail = inspector().inspect(inAppMessage: inAppMessage, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET, user: HackleUser.builder().build(), now: Date())
                guard case .target = detail else { fail("expected .target"); return }
            }

            it("FREQUENCY_CAPPED reason이면 .frequency를 반환") {
                let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger())
                let detail = inspector().inspect(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED, user: HackleUser.builder().build(), now: Date())
                guard case .frequency = detail else { fail("expected .frequency"); return }
            }

            it("HIDDEN reason이면 .hidden + expireAt") {
                let hiddenStorage = DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
                let inAppMessage = InAppMessage.create(id: 42)
                let expireAt = Date(timeIntervalSince1970: 2_000_000)
                hiddenStorage.put(inAppMessage: inAppMessage, expireAt: expireAt)
                let sut = InAppMessageDebugInspector(
                    impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                    hiddenStorage: hiddenStorage,
                    valueOperatorMatcher: DefaultValueOperatorMatcher(valueMatcherFactory: ValueMatcherFactory(), operatorMatcherFactory: OperatorMatcherFactory()),
                    userValueResolver: DefaultUserValueResolver()
                )

                let detail = sut.inspect(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_HIDDEN, user: HackleUser.builder().build(), now: Date())

                guard case .hidden(let hidden) = detail else { fail("expected .hidden"); return }
                expect(hidden.expireAt?.timeIntervalSince1970) == 2_000_000
            }

            it("그 외 reason이면 nil") {
                let inAppMessage = InAppMessage.create()
                let detail = inspector().inspect(inAppMessage: inAppMessage, reason: DecisionReason.IN_APP_MESSAGE_PAUSED, user: HackleUser.builder().build(), now: Date())
                expect(detail).to(beNil())
            }
        }
    }
}
