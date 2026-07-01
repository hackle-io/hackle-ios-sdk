import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageEvaluateProcessorSpecs: QuickSpec {
    override class func spec() {

        var evaluateProcessor: EvaluateProcessor!
        var sut: DefaultInAppMessageEvaluateProcessor!

        beforeEach {
            evaluateProcessor = EvaluateProcessor.create(
                context: EvaluationContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
            )
            sut = DefaultInAppMessageEvaluateProcessor(evaluateProcessor: evaluateProcessor)
        }

        it("trigger evaluate") {
            // given
            let inAppMessage = InAppMessage.create(status: .active)
            let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage, scope: .trigger)

            // when
            let actual = try sut.process(type: .trigger, request: request)

            // then
            expect(actual.inAppMessage.id) == inAppMessage.id
            expect(actual.eligibilityResult.isEligible) == true
        }

        it("deliver evaluate") {
            // given
            let inAppMessage = InAppMessage.create(status: .active)
            let request = InAppMessage.eligibilityRequest(inAppMessage: inAppMessage, scope: .deliver)

            // when
            let actual = try sut.process(type: .deliver, request: request)

            // then
            expect(actual.inAppMessage.id) == inAppMessage.id
            expect(actual.eligibilityResult.isEligible) == true
        }
    }
}
