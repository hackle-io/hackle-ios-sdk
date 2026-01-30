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
            let engagement = Engagement(screen: Screen.builder(name: "name", className: "class").build(), duration: 42.0)
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

        it("includes custom screen properties in $engagement event") {
            // given
            every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
            let screen = Screen.builder(name: "Detail", className: "DetailVC")
                .property("session_id", "session-12345")
                .property("product_id", "ABC-123")
                .property("user_tier", "premium")
                .build()
            let engagement = Engagement(screen: screen, duration: 5000.0)
            let user = User.builder().build()

            // when
            sut.onEngagement(engagement: engagement, user: user, timestamp: Date())

            // then
            verify(exactly: 1) {
                core.trackMock
            }
            let (event, _, _) = core.trackMock.firstInvokation().arguments
            expect(event.key).to(equal("$engagement"))
            expect(event.properties!["$engagement_time_ms"] as? Int64).to(equal(5000000))
            expect(event.properties!["$page_name"] as? String).to(equal("Detail"))
            expect(event.properties!["$page_class"] as? String).to(equal("DetailVC"))
            expect(event.properties!["session_id"] as? String).to(equal("session-12345"))
            expect(event.properties!["product_id"] as? String).to(equal("ABC-123"))
            expect(event.properties!["user_tier"] as? String).to(equal("premium"))
        }

        it("merges screen properties with engagement_time_ms") {
            // given
            every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
            let screen = Screen.builder(name: "Game", className: "GameVC")
                .property("level", 10)
                .property("score", 9999)
                .build()
            let engagement = Engagement(screen: screen, duration: 3456.78)
            let user = User.builder().build()

            // when
            sut.onEngagement(engagement: engagement, user: user, timestamp: Date())

            // then
            verify(exactly: 1) {
                core.trackMock
            }
            let (event, _, _) = core.trackMock.firstInvokation().arguments
            // Engagement time should be preserved
            expect(event.properties!["$engagement_time_ms"] as? Int64).to(equal(3456780))
            // Screen info should be preserved
            expect(event.properties!["$page_name"] as? String).to(equal("Game"))
            expect(event.properties!["$page_class"] as? String).to(equal("GameVC"))
            // Custom properties should be added
            expect(event.properties!["level"] as? Int).to(equal(10))
            expect(event.properties!["score"] as? Int).to(equal(9999))
        }

        it("works with empty screen properties") {
            // given
            every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
            let screen = Screen.builder(name: "Empty", className: "EmptyVC").build()
            let engagement = Engagement(screen: screen, duration: 100.0)
            let user = User.builder().build()

            // when
            sut.onEngagement(engagement: engagement, user: user, timestamp: Date())

            // then
            verify(exactly: 1) {
                core.trackMock
            }
            let (event, _, _) = core.trackMock.firstInvokation().arguments
            expect(event.key).to(equal("$engagement"))
            expect(event.properties!["$engagement_time_ms"] as? Int64).to(equal(100000))
            expect(event.properties!["$page_name"] as? String).to(equal("Empty"))
            expect(event.properties!["$page_class"] as? String).to(equal("EmptyVC"))
            // No custom properties should be present
            expect(event.properties!.keys.filter { !$0.hasPrefix("$") }.count).to(equal(0))
        }
    }
}
