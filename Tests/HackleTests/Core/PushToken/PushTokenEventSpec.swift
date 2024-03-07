import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class PushTokenEventSpec: QuickSpec {
    override func spec() {
        it("register push token event") {
            let event = RegisterPushTokenEvent(token: "abcd1234")
                .toTrackEvent()
            expect(event.key) == "$push_token"
            expect(event.properties?["provider_type"] as? String) == "APN"
            expect(event.properties?["token"] as? String) == "abcd1234"
        }
    }
}
