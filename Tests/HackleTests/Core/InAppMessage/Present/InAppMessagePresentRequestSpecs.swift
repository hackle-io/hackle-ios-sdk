import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessagePresentRequestSpecs: QuickSpec {
    override class func spec() {
        it("trigger event is taken from deliverRequest.triggerEvent") {
            let event = Event.builder("checkout").value(42.0).property("step", "review").build()
            let deliverRequest = InAppMessage.deliverRequest(triggerEvent: event)
            let inAppMessage = InAppMessage.create()
            let user = HackleUser.builder().identifier(.id, "user").build()
            let eligibility = InAppMessage.eligibilityEvaluation()
            let layout = InAppMessage.layoutEvaluateResponse()
            let deliverEvaluation = InAppMessageDeliverEvaluation(eligibility: eligibility, layout: layout)

            let request = InAppMessagePresentRequest.of(
                request: deliverRequest,
                inAppMessage: inAppMessage,
                user: user,
                deliverEvaluation: deliverEvaluation
            )

            expect(request.triggerEvent.key) == "checkout"
            expect(request.triggerEvent.value) == 42.0
            expect(request.triggerEvent.properties?["step"] as? String) == "review"
        }
    }
}
