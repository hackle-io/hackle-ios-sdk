import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageLayoutResolverSpecs: QuickSpec {
    override class func spec() {

        it("resolve") {
            // given
            let evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
            )
            let sut = DefaultInAppMessageLayoutResolver(evaluateProcessor: evaluateProcessor)

            let workspace = DefaultWorkspaceConfig.create()
            let inAppMessage = InAppMessageEntity.create()
            let user = HackleUser.of(userId: "test")

            // when
            let actual = try sut.resolve(workspace: workspace, inAppMessage: inAppMessage, user: user)

            // then
            expect(actual.layoutEvaluation.inAppMessage.id) == inAppMessage.id
            expect(actual.layoutEvaluation.layoutResult.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
        }
    }
}
