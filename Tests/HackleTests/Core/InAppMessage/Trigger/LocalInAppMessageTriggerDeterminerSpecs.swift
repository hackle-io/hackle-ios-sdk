import Foundation
import Nimble
import Quick

@testable import Hackle

class LocalInAppMessageTriggerDeterminerSpecs: QuickSpec {
    override class func spec() {

        var workspaceFetcher: MockWorkspaceConfigFetcher!
        var eventMatcher: InAppMessageTriggerEventMatcherStub!
        var evaluateProcessor: InAppMessageEvaluateProcessorStub!
        var sut: LocalInAppMessageTriggerDeterminer!

        beforeEach {
            workspaceFetcher = MockWorkspaceConfigFetcher()
            eventMatcher = InAppMessageTriggerEventMatcherStub()
            evaluateProcessor = InAppMessageEvaluateProcessorStub()
            sut = LocalInAppMessageTriggerDeterminer(
                eventMatcher: eventMatcher,
                workspaceFetcher: workspaceFetcher,
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
            every(workspaceFetcher.workspaceMock).returns(nil)

            let event = UserEvents.track("test")

            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("when inAppMessage is empty then return nil") {
            // given
            let workspace = DefaultWorkspaceConfig.create()
            every(workspaceFetcher.workspaceMock).returns(workspace)

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
            let workspace = DefaultWorkspaceConfig.create(
                inAppMessages: decisions.map { _ in
                    inAppMessage
                }
            )
            every(workspaceFetcher.workspaceMock).returns(workspace)
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
