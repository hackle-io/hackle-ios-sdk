import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class SessionEventTrackerSpecs: QuickSpec {
    override func spec() {

        it("onSessionStarted") {
            let userResolver = DefaultHackleUserResolver(device: Device(id: "device_id", properties: [:]))
            let internalApp = HackleCoreStub()
            let sut = SessionEventTracker(hackleUserResolver: userResolver, core: internalApp)

            let session = Session(id: "42.ffffffff")
            let user = User.builder().id("user_id").build()
            sut.onSessionStarted(session: session, user: user, timestamp: Date(timeIntervalSince1970: 42))

            expect(internalApp.tracked.count) == 1
            expect(internalApp.tracked[0].0.key) == "$session_start"
            expect(internalApp.tracked[0].1.sessionId) == "42.ffffffff"
            expect(internalApp.tracked[0].2.timeIntervalSince1970) == 42
        }

        it("onSessionEnded") {
            let userResolver = DefaultHackleUserResolver(device: Device(id: "device_id", properties: [:]))
            let internalApp = HackleCoreStub()
            let sut = SessionEventTracker(hackleUserResolver: userResolver, core: internalApp)

            let session = Session(id: "42.ffffffff")
            let user = User.builder().id("user_id").build()
            sut.onSessionEnded(session: session, user: user, timestamp: Date(timeIntervalSince1970: 42))

            expect(internalApp.tracked.count) == 1
            expect(internalApp.tracked[0].0.key) == "$session_end"
            expect(internalApp.tracked[0].1.sessionId) == "42.ffffffff"
            expect(internalApp.tracked[0].2.timeIntervalSince1970) == 42
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
