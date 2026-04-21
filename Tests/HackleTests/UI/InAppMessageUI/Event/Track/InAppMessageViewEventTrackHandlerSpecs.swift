import Foundation
@testable import Hackle
import Nimble
import Quick

class InAppMessageViewEventTrackHandlerSpecs: QuickSpec {
    override class func spec() {
        var tracker: MockInAppMessageEventTracker!
        var sut: InAppMessageViewEventTrackHandler!

        beforeEach {
            tracker = MockInAppMessageEventTracker()
            sut = InAppMessageViewEventTrackHandler(tracker: tracker)
        }

        it("supporces") {
            for type in InAppMessageViewEventHandleType.allCases {
                expect(sut.supports(handleType: type)).to(equal(type == .track))
            }
        }

        it("handle") {
            let view = MockInAppMessageView()
            let event = InAppMessageViewImpressionEvent(timestamp: Date())

            MainActor.assumeIsolated {
                sut.handle(view: view, event: event)
            }

            verify(exactly: 1) {
                tracker.trackMock
            }
        }
    }
}
