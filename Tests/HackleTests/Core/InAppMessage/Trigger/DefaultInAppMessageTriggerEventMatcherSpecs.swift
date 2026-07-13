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

        describe("실물 TargetMatcher 배선 - 트리거 단계는 이벤트 기반 조건을 평가한다") {

            // 트리거 단계는 이벤트 기반 조건(EVENT_PROPERTY 등)만 평가한다.
            // SEGMENT/AB_TEST 등 전체 타겟팅은 트리거가 아니라 eligibility 단계에서 판단한다.
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

            it("EVENT_PROPERTY 조건은 트리거 단계에서 평가된다") {
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
