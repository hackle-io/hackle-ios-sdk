import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageEvaluatorSpecs: QuickSpec {
    override func spec() {
        var core: MockHackleCore!
        var eligibilityEvaluator: MockEvaluator!
        var sut: DefaultInAppMessageEvaluator!

        beforeEach {
            core = MockHackleCore()
            eligibilityEvaluator = MockEvaluator()
            sut = DefaultInAppMessageEvaluator(core: core, eligibilityEvaluator: eligibilityEvaluator)
        }

        it("evaluate") {
            // given
            let workspace = WorkspaceEntity.create()
            let inAppMessage = InAppMessage.create()
            let user = HackleUser.builder().identifier(.device, "device").build()
            let timestamp = Date(timeIntervalSince1970: 42)

            let evaluation = InAppMessage.eligibilityEvaluation(
                reason: DecisionReason.OVERRIDDEN,
                isEligible: true
            )
            every(core.evaluateMock).returns(evaluation)

            // when
            let actual = try sut.evaluate(workspace: workspace, inAppMessage: inAppMessage, user: user, timestamp: timestamp)

            // then
            expect(actual.isEligible) == true
            expect(actual.reason) == "OVERRIDDEN"
        }
    }
}
