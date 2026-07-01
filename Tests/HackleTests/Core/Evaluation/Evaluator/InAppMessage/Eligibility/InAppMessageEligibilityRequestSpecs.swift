import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityRequestSpecs: QuickSpec {
    override class func spec() {

        it("of") {
            let workspace = MockWorkspace()
            let user = HackleUser.builder().identifier(.id, "user").build()
            let timestamp = Date(timeIntervalSince1970: 42)

            let request = InAppMessageEligibilityLocalEvaluateRequest.of(
                workspace: workspace,
                inAppMessage: InAppMessage.create(id: 1),
                user: user,
                scope: .trigger,
                timestamp: timestamp
            )

            expect(request.inAppMessage.id) == 1
            if case .trigger = request.scope {} else { fail("expected .trigger") }
            expect(request.timestamp) == timestamp
            expect(request.record) == true
        }
    }
}
