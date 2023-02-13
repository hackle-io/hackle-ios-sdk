import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class SessionEventTrackerSpecs: QuickSpec {
    override func spec() {

        it("onSessionStarted") {
            let userResolver = DefaultHackleUserResolver(device: Device(id: "device_id", properties: [:]))
            let internalApp = HackleInternalAppStub()
            let sut = SessionEventTracker(hackleUserResolver: userResolver, internalApp: internalApp)

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
            let internalApp = HackleInternalAppStub()
            let sut = SessionEventTracker(hackleUserResolver: userResolver, internalApp: internalApp)

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

fileprivate class HackleInternalAppStub: HackleInternalApp {

    var tracked = [(Event, HackleUser, Date)]()

    func initialize(completion: @escaping () -> ()) {

    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision {
        fatalError("experiment(experimentKey:user:defaultVariationKey:) has not been implemented")
    }

    func experiments(user: HackleUser) throws -> [Int: Decision] {
        fatalError("experiments(user:) has not been implemented")
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        fatalError("featureFlag(featureKey:user:) has not been implemented")
    }

    func track(event: Event, user: HackleUser) {
    }

    func track(event: Event, user: HackleUser, timestamp: Date) {
        tracked.append((event, user, timestamp))
    }

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        fatalError("remoteConfig(parameterKey:user:defaultValue:) has not been implemented")
    }
}