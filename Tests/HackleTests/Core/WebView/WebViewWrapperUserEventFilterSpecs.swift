import Foundation
import Quick
import Nimble
@testable import Hackle

class WebViewWrapperUserEventFilterSpecs: QuickSpec {
    override func spec() {
        it("when not push event then block") {
            let sut = WebViewWrapperUserEventFilter()
            let actual = sut.check(event: UserEvents.track("test"))
            expect(actual).to(equal(UserEventFilterResult.block))
        }

        it("when deviceId is nul then block") {
            let sut = WebViewWrapperUserEventFilter()
            let user = HackleUser.builder().build()
            let actual = sut.check(event: UserEvents.track("$push_token", user: user))
            expect(actual).to(equal(UserEventFilterResult.block))
        }

        it("when hackleDeviceId is nil then block") {
            let sut = WebViewWrapperUserEventFilter()
            let user = HackleUser.builder().identifier(.device, "device").build()
            let actual = sut.check(event: UserEvents.track("$push_token", user: user))
            expect(actual).to(equal(UserEventFilterResult.block))
        }

        it("when deviceId == hackleDeviceId then block") {
            let sut = WebViewWrapperUserEventFilter()
            let user = HackleUser.builder().identifier(.device, "device").identifier(.hackleDevice, "device").build()
            let actual = sut.check(event: UserEvents.track("$push_token", user: user))
            expect(actual).to(equal(UserEventFilterResult.block))
        }

        it("pass") {
            let sut = WebViewWrapperUserEventFilter()
            let user = HackleUser.builder().identifier(.device, "device").identifier(.hackleDevice, "hackle_device").build()
            let actual = sut.check(event: UserEvents.track("$push_token", user: user))
            expect(actual).to(equal(UserEventFilterResult.pass))
        }
    }
}
