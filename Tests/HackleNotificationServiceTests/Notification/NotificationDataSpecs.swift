//
//  NotificationDataSpecs.swift
//  HackleNotificationServiceTests
//

import Quick
import Nimble
import Foundation
@testable import HackleNotificationService

class NotificationDataSpecs: QuickSpec {
    override class func spec() {
        func payload(_ buttons: Any?) -> [AnyHashable: Any] {
            var hackle: [String: Any] = ["workspaceId": 123, "environmentId": 456]
            if let buttons = buttons {
                hackle["buttons"] = buttons
            }
            return ["hackle": hackle]
        }

        describe("NotificationData.from buttons") {
            it("parses categoryId and titles in order") {
                let buttons: [String: Any] = [
                    "categoryId": "hackle_marketing_push_deny",
                    "items": [
                        ["title": "수신거부", "clickAction": "DEEP_LINK", "link": "myapp://settings/marketing"],
                        ["title": "열기"]
                    ]
                ]
                let data = NotificationData.from(data: payload(buttons))
                expect(data?.categoryId) == "hackle_marketing_push_deny"
                expect(data?.buttonTitles) == ["수신거부", "열기"]
            }

            it("has no buttons when buttons is missing") {
                let data = NotificationData.from(data: payload(nil))
                expect(data).toNot(beNil())
                expect(data?.categoryId).to(beNil())
                expect(data?.buttonTitles) == []
            }

            it("has no titles when items is empty") {
                let data = NotificationData.from(data: payload(["categoryId": "hackle_a", "items": [Any]()]))
                expect(data?.buttonTitles) == []
            }

            it("has no categoryId when categoryId is missing") {
                let data = NotificationData.from(data: payload(["items": [["title": "a"]]]))
                expect(data?.categoryId).to(beNil())
            }

            it("ignores buttons of wrong type") {
                let inputs: [Any] = ["buttons", [1, 2], ["categoryId": 1, "items": "x"]]
                for input in inputs {
                    let data = NotificationData.from(data: payload(input))
                    expect(data).toNot(beNil())
                    expect(data?.categoryId).to(beNil())
                    expect(data?.buttonTitles) == []
                }
            }

            it("drops all titles when any item has no string title") {
                let buttons: [String: Any] = [
                    "categoryId": "hackle_a",
                    "items": [["title": "a"], ["title": 1], "x"]
                ]
                let data = NotificationData.from(data: payload(buttons))
                expect(data?.buttonTitles) == []
            }
        }
    }
}
