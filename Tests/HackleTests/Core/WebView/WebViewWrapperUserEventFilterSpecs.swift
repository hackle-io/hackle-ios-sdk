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
        
        it("webview wrapper filter return filtered event") {
            // given
            let sut = WebViewWrapperUserEventFilter()
            let user = HackleUser.builder().identifier(.device, "device").identifier(.hackleDevice, "hackle_device").build()
            let event = UserEvents.track("$push_token", user: user)
            
            // when
            let actual = sut.filter(event: event)
            // then
            expect(actual.user).toNot(beIdenticalTo(event.user))
            expect(actual.user.properties.count).to(equal(0))
            expect(actual.timestamp).to(equal(event.timestamp))
            expect(actual.type).to(equal(event.type))
            expect(actual.insertId).to(equal(event.insertId))
        }
    }
}
