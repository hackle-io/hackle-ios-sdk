import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageLayoutRequestSpecs: QuickSpec {
    override func spec() {
        it("==") {
            let workspace = WorkspaceEntity.create()
            let user = HackleUser.builder().identifier(.id, "user").build()

            let r1 = InAppMessageLayoutRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(id: 1))
            let r1_ = InAppMessageLayoutRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(id: 1))
            let r2 = InAppMessageLayoutRequest(workspace: workspace, user: user, inAppMessage: InAppMessage.create(id: 3))

            expect(r1) == r1_
            expect(r1) != r2
        }
    }
}
