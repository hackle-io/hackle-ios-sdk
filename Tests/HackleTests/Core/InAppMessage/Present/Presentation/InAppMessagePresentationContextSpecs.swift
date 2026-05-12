import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessagePresentationContextSpecs: QuickSpec {
    override class func spec() {
        it("trigger event is taken from presentRequest.triggerEvent") {
            let event = Event.builder("share").property("channel", "kakao").build()
            let presentRequest = InAppMessage.presentRequest(triggerEvent: event)

            let context = InAppMessagePresentationContext.of(request: presentRequest)

            expect(context.triggerEvent.key) == "share"
            expect(context.triggerEvent.properties?["channel"] as? String) == "kakao"
        }
    }
}
