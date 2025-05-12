import Foundation
import Quick
import Nimble
@testable import Hackle

class EngagementEventTrackerSpecs: QuickSpec {
    override func spec() {
        var userManager: MockUserManager!
        var core: MockHackleCore!
        var sut: EngagementEventTracker!

        beforeEach {
            userManager = MockUserManager()
            core = MockHackleCore()
            sut = EngagementEventTracker(userManager: userManager, core: core)
        }

        it("track") {
            // given
            every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
            let engagement = Engagement(screen: Screen(name: "name", className: "class"), duration: 42.0)
            let user = User.builder().build()

            // when
            sut.onEngagement(engagement: engagement, user: user, timestamp: Date(timeIntervalSince1970: 100))

            // then
            verify(exactly: 1) {
                core.trackMock
            }
            let (event, _, _) = core.trackMock.firstInvokation().arguments
            expect(event.key).to(equal("$engagement"))
            expect(event.properties!["$engagement_time_ms"] as? Int64).to(equal(42000))
            expect(event.properties!["$page_name"] as? String).to(equal("name"))
            expect(event.properties!["$page_class"] as? String).to(equal("class"))
        }
    }
}
