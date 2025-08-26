import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessagePresentationContextResolverSpecs: QuickSpec {
    override func spec() {

        var core: MockHackleCore!
        var layoutEvaluator: MockEvaluator!
        var sut: DefaultInAppMessagePresentationContextResolver!

        beforeEach {
            core = MockHackleCore()
            layoutEvaluator = MockEvaluator()
            sut = DefaultInAppMessagePresentationContextResolver(core: core, layoutEvaluator: layoutEvaluator)
        }

        it("evaluate") {
            // given
            let inAppMessage = InAppMessage.create()
            let message = inAppMessage.messageContext.messages[0]
            let request = InAppMessage.presentRequest(
                dispatchId: "111",
                inAppMessage: inAppMessage,
                evaluation: InAppMessageEvaluation(isEligible: true, reason: DecisionReason.OVERRIDDEN),
                properties: ["present": "request"],
                )

            let evaluation = InAppMessageLayoutEvaluation(
                reason: DecisionReason.IN_APP_MESSAGE_TARGET,
                targetEvaluations: [],
                inAppMessage: inAppMessage,
                message: message,
                properties: ["layout": "evaluation"]
            )
            every(core.evaluateMock).returns(evaluation)

            // when
            let actual = try sut.resolve(request: request)

            // then
            expect(actual.dispatchId) == "111"
            expect(actual.inAppMessage).to(beIdenticalTo(inAppMessage))
            expect(actual.message).to(beIdenticalTo(message))
            expect(actual.decisionReasion) == "OVERRIDDEN"
            expect(actual.properties.count) == 2
            expect(actual.properties["present"] as! String) == "request"
            expect(actual.properties["layout"] as! String) == "evaluation"
        }
    }
}
