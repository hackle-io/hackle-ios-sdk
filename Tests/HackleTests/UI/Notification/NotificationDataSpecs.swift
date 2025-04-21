import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class NotificationDataSpecs: QuickSpec {
    override func spec() {
        it("from dictionary") {
            let data = ["hackle": [
                "workspaceId": 123,
                "environmentId": 456,
                "pushMessageId": 1,
                "pushMessageKey": 2,
                "pushMessageExecutionId": 3,
                "pushMessageDeliveryId": 4,
                "showForeground": true,
                "debug": true,
                "imageUrl": "https://foo.bar",
                "clickAction": "DEEP_LINK",
                "link": "app://main"
            ]]
            let result = NotificationData.from(data: data)

            expect(result).toNot(beNil())
            expect(result?.workspaceId) == 123
            expect(result?.environmentId) == 456
            expect(result?.pushMessageId) == 1
            expect(result?.pushMessageKey) == 2
            expect(result?.pushMessageExecutionId) == 3
            expect(result?.pushMessageDeliveryId) == 4
            expect(result?.showForeground) == true
            expect(result?.debug) == true
            expect(result?.imageUrl) == "https://foo.bar"
            expect(result?.clickAction) == NotificationClickAction.deepLink
            expect(result?.link) == "app://main"
            expect(result?.type) == HackleNotificationClickActionType.deepLink
            expect(result?.deepLink) == "app://main"
        }
        it("from dictionary with invalid hackle key value") {
            expect(NotificationData.from(data: [:])).to(beNil())
            expect(NotificationData.from(data: ["hackle":""])).to(beNil())
            expect(NotificationData.from(data: ["hackle":"123"])).to(beNil())
            expect(NotificationData.from(data: ["hackle":"{}"])).to(beNil())
            expect(NotificationData.from(data: ["hackle":"{}}"])).to(beNil())
            expect(NotificationData.from(data: ["hackle":"\"foo\""])).to(beNil())
            expect(NotificationData.from(data: ["hackle":"{\"123\":123}"])).to(beNil())
        }
        it("from dictionary with required values only") {
            let data = ["hackle": [
                "workspaceId": 123,
                "environmentId": 456
            ]]
            let result = NotificationData.from(data: data)

            expect(result).toNot(beNil())
            expect(result?.workspaceId) == 123
            expect(result?.environmentId) == 456
            expect(result?.pushMessageId).to(beNil())
            expect(result?.pushMessageKey).to(beNil())
            expect(result?.pushMessageExecutionId).to(beNil())
            expect(result?.pushMessageDeliveryId).to(beNil())
            expect(result?.showForeground) == false
            expect(result?.debug) == false
            expect(result?.imageUrl).to(beNil())
            expect(result?.clickAction) == NotificationClickAction.appOpen
            expect(result?.link).to(beNil())
            expect(result?.type) == HackleNotificationClickActionType.appOpen
            expect(result?.deepLink).to(beNil())
        }
        it("from dictionary without workspace id") {
            let data = ["hackle": [
                "environmentId": 456,
                "pushMessageId": 1,
                "pushMessageKey": 2,
                "pushMessageExecutionId": 3,
                "pushMessageDeliveryId": 4,
                "showForeground": true,
                "debug": true,
                "imageUrl": "https://foo.bar",
                "clickAction": "DEEP_LINK",
                "link": "app://main"
            ]]
            let result = NotificationData.from(data: data)
            expect(result).to(beNil())
        }
        it("from dictionary without environment id") {
            let data = ["hackle": [
                "workspaceId": 123,
                "pushMessageId": 1,
                "pushMessageKey": 2,
                "pushMessageExecutionId": 3,
                "pushMessageDeliveryId": 4,
                "showForeground": true,
                "debug": true,
                "imageUrl": "https://foo.bar",
                "clickAction": "DEEP_LINK",
                "link": "app://main"
            ]]
            let result = NotificationData.from(data: data)
            expect(result).to(beNil())
        }
    }
}
