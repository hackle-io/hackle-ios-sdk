import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageLayoutResolverSpecs: QuickSpec {
    override class func spec() {

        it("resolve") {
            // given
            let evaluateProcessor = EvaluateProcessor.create(
                context: EvaluationContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
            )
            let sut = DefaultInAppMessageLayoutResolver(evaluateProcessor: evaluateProcessor)

            let workspace = WorkspaceEntity.create()
            let inAppMessage = InAppMessage.create()
            let user = HackleUser.of(userId: "test")

            // when
            let actual = try sut.resolve(workspace: workspace, inAppMessage: inAppMessage, user: user)

            // then
            expect(actual.inAppMessage.id) == inAppMessage.id
            expect(actual.layoutResult.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
        }
    }
}
