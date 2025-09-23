import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class SessionEventTrackerSpecs: QuickSpec {
    override func spec() {

        var userManager: MockUserManager!
        var core: HackleCoreStub!
        var sut: SessionEventTracker!

        beforeEach {
            userManager = MockUserManager()
            core = HackleCoreStub()
            sut = SessionEventTracker(userManager: userManager, core: core)
        }

        it("onSessionStarted") {
            let hackleUser = HackleUser.builder().identifier(.id, "user").build()
            every(userManager.toHackleUserMock).returns(hackleUser)

            let session = Session(id: "42.ffffffff")
            let user = User.builder().id("user_id").build()
            sut.onSessionStarted(session: session, user: user, timestamp: Date(timeIntervalSince1970: 42))

            expect(core.tracked.count) == 1
            expect(core.tracked[0].0.key) == "$session_start"
            expect(core.tracked[0].1.sessionId) == "42.ffffffff"
            expect(core.tracked[0].2.timeIntervalSince1970) == 42
        }

        it("onSessionEnded") {
            let hackleUser = HackleUser.builder().identifier(.id, "user").build()
            every(userManager.toHackleUserMock).returns(hackleUser)

            let session = Session(id: "42.ffffffff")
            let user = User.builder().id("user_id").build()
            sut.onSessionEnded(session: session, user: user, timestamp: Date(timeIntervalSince1970: 42))

            expect(core.tracked.count) == 1
            expect(core.tracked[0].0.key) == "$session_end"
            expect(core.tracked[0].1.sessionId) == "42.ffffffff"
            expect(core.tracked[0].2.timeIntervalSince1970) == 42
        }

        it("isSessionEvent") {
            expect(SessionEventTracker.isSessionEvent(event: trackEvent(key: "custom"))) == false
            expect(SessionEventTracker.isSessionEvent(event: MockUserEvent(user: HackleUser.builder().build()))) == false
            expect(SessionEventTracker.isSessionEvent(event: trackEvent(key: "$session_start"))) == true
            expect(SessionEventTracker.isSessionEvent(event: trackEvent(key: "$session_end"))) == true
        }

        func trackEvent(key: String) -> UserEvent {
            UserEvents.track(eventType: UndefinedEventType(key: key), event: Hackle.event(key: key), timestamp: Date(), user: HackleUser.builder().build())
        }
    }
}
