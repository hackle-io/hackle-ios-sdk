import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageTriggerEventMatcherSpecs: QuickSpec {
    override class func spec() {

        var targetMatcher: TargetMatcherStub!
        var sut: DefaultInAppMessageTriggerEventMatcher!

        var workspace: MockWorkspace!

        beforeEach {
            targetMatcher = TargetMatcherStub()
            sut = DefaultInAppMessageTriggerEventMatcher(targetMatcher: targetMatcher)
            workspace = MockWorkspace()
        }

        it("when trigger rule is empty then returns false") {
            // given
            let event = UserEvents.track("test")
            let inAppMessage = InAppMessageEntity.create(eventTrigger: InAppMessageEntity.eventTrigger(rules: []))

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

            // then
            expect(actual) == false
        }

        it("when all trigger rules do not match then returns false") {
            // given
            let event = UserEvents.track("test")
            let inAppMessage = InAppMessageEntity.create(eventTrigger: InAppMessageEntity.eventTrigger(rules: [
                InAppMessage.EventTrigger.Rule(eventKey: "not_match", targets: []),
                InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition(), Target.condition())]),
            ]))
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
            let inAppMessage = InAppMessageEntity.create(eventTrigger: InAppMessageEntity.eventTrigger(rules: [
                InAppMessage.EventTrigger.Rule(eventKey: "not_match", targets: []),
                InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
                InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [.create(Target.condition())]),
            ]))
            targetMatcher.isMatches = [false, false, true, false]

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

            // then
            expect(actual) == true
            expect(targetMatcher.callCount) == 3
        }

        describe("LOCAL 평가 불가 조건 타입 - 실물 TargetMatcher (신 아키텍처 의미 고정)") {

            var realSut: DefaultInAppMessageTriggerEventMatcher!

            beforeEach {
                realSut = DefaultInAppMessageTriggerEventMatcher(
                    targetMatcher: DefaultTargetMatcher(
                        conditionMatcherFactory: DefaultConditionMatcherFactory(
                            evaluator: DelegatingEvaluator(evaluatorFactory: EvaluatorFactory()),
                            clock: FixedClock(date: Date())
                        )
                    )
                )
            }

            func rule(_ conditions: Target.Condition...) -> InAppMessage.EventTrigger.Rule {
                InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [Target(conditions: conditions)])
            }

            it("SEGMENT 조건이 든 트리거 룰은 매치되지 않는다 (Request가 LocalEvaluateRequest 미채택 - silent false)") {
                let event = UserEvents.track("test")
                let inAppMessage = InAppMessageEntity.create(eventTrigger: InAppMessageEntity.eventTrigger(rules: [
                    rule(Target.condition(
                        key: Target.key(type: .segment, name: "SEGMENT"),
                        match: Target.match(values: [.string("seg_01")])
                    ))
                ]))

                let actual = try realSut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

                expect(actual) == false
            }

            it("AB_TEST 조건이 든 트리거 룰은 매치되지 않는다") {
                let event = UserEvents.track("test")
                let inAppMessage = InAppMessageEntity.create(eventTrigger: InAppMessageEntity.eventTrigger(rules: [
                    rule(Target.condition(
                        key: Target.key(type: .abTest, name: "42"),
                        match: Target.match(values: [.string("A")])
                    ))
                ]))

                let actual = try realSut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

                expect(actual) == false
            }

            it("EVENT_PROPERTY 조건은 여전히 평가된다 (비대칭)") {
                let event = UserEvents.track("test", properties: ["amount": "hackle"])
                let inAppMessage = InAppMessageEntity.create(eventTrigger: InAppMessageEntity.eventTrigger(rules: [
                    rule(Target.condition(
                        key: Target.key(type: .eventProperty, name: "amount"),
                        match: Target.match(values: [.string("hackle")])
                    ))
                ]))

                let actual = try realSut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

                expect(actual) == true
            }
        }
    }
}
