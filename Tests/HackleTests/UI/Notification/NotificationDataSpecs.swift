import Foundation
import Quick
import Nimble
import MockingKit
import UserNotifications
@testable import Hackle

class NotificationDataSpecs: QuickSpec {
    override class func spec() {
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
            expect(result?.actionType) == HackleNotificationClickActionType.link
            expect(result?.link) == "app://main"
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
            expect(result?.actionType) == HackleNotificationClickActionType.appOpen
            expect(result?.link).to(beNil())
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

        func payload(buttons: Any?) -> [String: Any] {
            var hackle: [String: Any] = [
                "workspaceId": 1,
                "environmentId": 2,
                "pushMessageId": 10,
                "clickAction": "DEEP_LINK",
                "link": "myapp://home"
            ]
            if let buttons = buttons {
                hackle["buttons"] = buttons
            }
            return ["hackle": hackle]
        }

        func makeButtons() -> [String: Any] {
            return [
                "categoryId": "hackle_marketing_push_deny",
                "items": [
                    ["type": "UNSUBSCRIBE", "title": "수신거부", "clickAction": "DEEP_LINK", "link": "myapp://settings/marketing"],
                    ["title": "열기", "clickAction": "APP_OPEN", "link": "myapp://ignored"]
                ]
            ]
        }

        describe("buttons") {
            it("parses buttons in order") {
                let result = NotificationData.from(data: payload(buttons: makeButtons()))

                expect(result?.buttons.count) == 2
                expect(result?.buttons[0].clickAction) == NotificationClickAction.deepLink
                expect(result?.buttons[0].link) == "myapp://settings/marketing"
                expect(result?.buttons[0].type) == "UNSUBSCRIBE"
                expect(result?.buttons[1].clickAction) == NotificationClickAction.appOpen
                expect(result?.buttons[1].type).to(beNil())
            }
            it("has no buttons") {
                let payloads: [[String: Any]] = [
                    payload(buttons: nil),
                    payload(buttons: "x"),
                    payload(buttons: ["items": []])
                ]
                for data in payloads {
                    let result = NotificationData.from(data: data)
                    expect(result).toNot(beNil())
                    expect(result?.buttons.isEmpty) == true
                }
            }
            it("keeps index for malformed items") {
                let result = NotificationData.from(data: payload(buttons: [
                    "items": ["x", ["clickAction": "DEEP_LINK", "link": "myapp://b"]]
                ]))

                expect(result?.buttons.count) == 2
                expect(result?.buttons[0].clickAction) == NotificationClickAction.appOpen
                expect(result?.buttons[1].link) == "myapp://b"
            }
            it("treats unknown clickAction as appOpen") {
                let result = NotificationData.from(data: payload(buttons: [
                    "items": [["clickAction": "WEB_URL", "link": "https://a"]]
                ]))

                expect(result?.buttons[0].clickAction) == NotificationClickAction.appOpen
            }
        }

        describe("from with actionIdentifier") {
            it("applies the tapped button action") {
                let result = NotificationData.from(data: payload(buttons: makeButtons()), actionIdentifier: "hackle_action_0")!

                expect(result.clickAction) == NotificationClickAction.deepLink
                expect(result.actionType) == HackleNotificationClickActionType.link
                expect(result.link) == "myapp://settings/marketing"
                expect(result.pushMessageId) == 10
                expect(result.buttons.count) == 2
                expect(result.clickArea) == NotificationClickArea.button
                expect(result.buttonType) == "UNSUBSCRIBE"

                let event = result.toTrackEvent()
                expect(event.properties?["push_message_click_area"] as? String) == "BUTTON"
                expect(event.properties?["push_message_click_action"] as? String) == "DEEP_LINK"
                expect(event.properties?["push_message_click_value"] as? String) == "myapp://settings/marketing"
                expect(event.properties?["push_message_button_type"] as? String) == "UNSUBSCRIBE"
            }
            it("applies an APP_OPEN button") {
                let result = NotificationData.from(data: payload(buttons: makeButtons()), actionIdentifier: "hackle_action_1")!

                expect(result.actionType) == HackleNotificationClickActionType.appOpen
                expect(result.link).to(beNil())
                expect(result.clickArea) == NotificationClickArea.button
                expect(result.buttonType).to(beNil())
            }
            it("keeps the body action for the default identifier") {
                let result = NotificationData.from(data: payload(buttons: makeButtons()), actionIdentifier: UNNotificationDefaultActionIdentifier)!

                expect(result.link) == "myapp://home"
                expect(result.clickArea) == NotificationClickArea.message
                expect(result.buttonType).to(beNil())
            }
            it("falls back to the body action for other identifiers") {
                let identifiers = [
                    "hackle_action_2",
                    "hackle_action_-1",
                    "hackle_action_x",
                    "hackle_action_",
                    "other_action",
                    UNNotificationDismissActionIdentifier
                ]

                for identifier in identifiers {
                    let result = NotificationData.from(data: payload(buttons: makeButtons()), actionIdentifier: identifier)!
                    expect(result.link) == "myapp://home"
                    expect(result.clickArea) == NotificationClickArea.message
                }
            }
        }
    }
}
