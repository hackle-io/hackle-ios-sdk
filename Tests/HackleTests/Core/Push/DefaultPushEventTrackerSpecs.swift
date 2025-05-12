import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultPushEventTrackerSpecs: QuickSpec {
    override func spec() {
        var userManager: MockUserManager!
        var core: MockHackleCore!
        var sut: DefaultPushEventTracker!

        beforeEach {
            userManager = MockUserManager()
            core = MockHackleCore()
            sut = DefaultPushEventTracker(userManager: userManager, core: core)
        }


        it("track push token") {
            // given
            every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
            let user = User.builder().deviceId("device_id").build()
            let pushToken = PushToken(platformType: .ios, providerType: .apn, value: "token_42")

            // when
            sut.trackPushToken(pushToken: pushToken, user: user, timestamp: Date(timeIntervalSince1970: 42))

            // then
            verify(exactly: 1) {
                core.trackMock
            }
            let event = core.trackMock.firstInvokation().arguments.0
            expect(event.key).to(equal("$push_token"))
            expect(event.properties?["provider_type"] as? String).to(equal("APN"))
            expect(event.properties?["token"] as? String).to(equal("token_42"))
        }

        context("PushEventKey") {
            it("isPushEvent") {
                expect(PushEventKey.isPushEvent(event: UserEvents.track("test"))).to(be(false))
                expect(PushEventKey.isPushEvent(event: UserEvents.track("$push_click"))).to(be(true))
                expect(PushEventKey.isPushEvent(event: UserEvents.track("$push_token"))).to(be(true))
            }
        }
    }
}
