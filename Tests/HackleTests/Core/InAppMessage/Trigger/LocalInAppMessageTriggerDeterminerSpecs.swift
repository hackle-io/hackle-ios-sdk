import Foundation
import Nimble
import Quick

@testable import Hackle

class LocalInAppMessageTriggerDeterminerSpecs: QuickSpec {
    override class func spec() {

        var workspaceFetcher: MockWorkspaceConfigFetcher!
        var eventMatcher: MockInAppMessageTriggerEventMatcher!
        var sut: LocalInAppMessageTriggerDeterminer!

        beforeEach {
            workspaceFetcher = MockWorkspaceConfigFetcher()
            eventMatcher = MockInAppMessageTriggerEventMatcher()
            let evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "iam_local_trigger_impression"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "iam_local_trigger_hidden")
            )
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

        it("when eventMatcher does not match then return nil") {
            // given
            let inAppMessage = InAppMessageEntity.create(key: 42)
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage]))
            every(eventMatcher.matchesMock).returns(false)

            let event = UserEvents.track("test")

            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual).to(beNil())
        }

        it("when eventMatcher matches and inAppMessage is eligible then return InAppMessageTrigger") {
            // given
            let inAppMessage = InAppMessageEntity.create(key: 42, status: .active)
            every(workspaceFetcher.workspaceMock).returns(DefaultWorkspaceConfig.create(inAppMessages: [inAppMessage]))
            every(eventMatcher.matchesMock).returns(true)

            let event = UserEvents.track("test")

            // when
            let actual = try sut.determine(event: event)

            // then
            expect(actual?.inAppMessage.id) == inAppMessage.id
            expect(actual?.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
            expect(actual?.event.event.key) == event.event.key
        }
    }
}
