import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageTriggerEventMatcherSpecs: QuickSpec {
    override func spec() {

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
            let inAppMessage = InAppMessage.create(eventTrigger: InAppMessage.eventTrigger(rules: []))

            // when
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

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
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

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
            let actual = try sut.matches(workspace: workspace, inAppMessage: inAppMessage, event: event)

            // then
            expect(actual) == true
            expect(targetMatcher.callCount) == 3
        }
    }
}
