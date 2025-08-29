import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageTriggerDeterminerSpecs: QuickSpec {
    override func spec() {

        var workspaceFetcher: MockWorkspaceFetcher!
        var eventMatcher: InAppMessageTriggerEventMatcherStub!
        var evaluateProcessor: InAppMessageEvaluateProcessorStub!
        var sut: DefaultInAppMessageTriggerDeterminer!

        beforeEach {
            workspaceFetcher = MockWorkspaceFetcher()
            eventMatcher = InAppMessageTriggerEventMatcherStub()
            evaluateProcessor = InAppMessageEvaluateProcessorStub()
            sut = DefaultInAppMessageTriggerDeterminer(
                workspaceFetcher: workspaceFetcher,
                eventMatcher: eventMatcher,
                evaluateProcessor: evaluateProcessor
            )
        }

        it("when event is not TrackEvent then return nil") {
            // given
            let event = UserEvents.exposure()

            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("when workspace is nil then return nil") {
            // given
            every(workspaceFetcher.fetchMock).returns(nil)

            let event = UserEvents.track("test")

            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("when inAppMessage is empty then return nil") {
            // given
            let workspace = WorkspaceEntity.create()
            every(workspaceFetcher.fetchMock).returns(workspace)

            let event = UserEvents.track("test")

            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("when all inAppMessage do not matched then return nil") {
            // given
            determine(
                decision(isEventMatched: false, isEligible: false, reason: DecisionReason.IN_APP_MESSAGE_DRAFT),
                decision(isEventMatched: true, isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
            )

            let event = UserEvents.track("test")

            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("when inAppMessage matched then trigger") {
            // given
            determine(
                decision(isEventMatched: false, isEligible: false, reason: DecisionReason.IN_APP_MESSAGE_DRAFT),
                decision(isEventMatched: true, isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET),
                decision(isEventMatched: true, isEligible: true, reason: DecisionReason.IN_APP_MESSAGE_TARGET),
                decision(isEventMatched: false, isEligible: false, reason: DecisionReason.IN_APP_MESSAGE_DRAFT)
            )

            let event = UserEvents.track("test")


            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual?.reason) == "IN_APP_MESSAGE_TARGET"
        }

        func determine(_ decisions: Decision...) {
            eventMatcher.matches = decisions.map {
                $0.isEventMacthed
            }
            evaluateProcessor.evaluations = decisions.filter {
                    $0.isEventMacthed
                }
                .map {
                    $0.evaluation
                }

            let inAppMessage = InAppMessage.create()
            let workspace = WorkspaceEntity.create(
                inAppMessages: decisions.map { _ in
                    inAppMessage
                }
            )
            every(workspaceFetcher.fetchMock).returns(workspace)
        }

        func decision(isEventMatched: Bool, isEligible: Bool, reason: String) -> Decision {

            return Decision(
                isEventMacthed: isEventMatched,
                evaluation: InAppMessage.eligibilityEvaluation(
                    reason: reason,
                    isEligible: isEligible,
                )
            )
        }

        struct Decision {
            var isEventMacthed: Bool
            var evaluation: InAppMessageEligibilityEvaluation
        }
    }
}
