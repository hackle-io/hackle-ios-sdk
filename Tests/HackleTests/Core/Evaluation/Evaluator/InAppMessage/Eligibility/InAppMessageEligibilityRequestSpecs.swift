import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityRequestSpecs: QuickSpec {
    override func spec() {

        it("==") {

            let workspace = MockWorkspace()
            let user = HackleUser.builder().identifier(.id, "user").build()

            let request1 = InAppMessageEligibilityRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(id: 1), timestamp: Date())
            let request1_ = InAppMessageEligibilityRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(id: 1), timestamp: Date())
            let request2 = InAppMessageEligibilityRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(id: 2), timestamp: Date())

            expect(request1) == request1_
            expect(request1) != request2
        }
    }
}