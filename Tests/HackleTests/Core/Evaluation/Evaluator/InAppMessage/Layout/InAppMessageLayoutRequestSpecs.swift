import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageLayoutRequestSpecs: QuickSpec {
    override class func spec() {
        it("of") {
            let workspace = WorkspaceEntity.create()
            let user = HackleUser.builder().identifier(.id, "user").build()

            let request = InAppMessageLayoutLocalEvaluateRequest.of(
                workspace: workspace,
                inAppMessage: InAppMessage.create(id: 1),
                user: user,
                scope: .trigger
            )

            expect(request.inAppMessage.id) == 1
            if case .trigger = request.scope {} else { fail("expected .trigger") }
            expect(request.record) == true
        }
    }
}
