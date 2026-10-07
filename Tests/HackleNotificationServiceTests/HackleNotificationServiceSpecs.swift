//
//  HackleNotificationServiceSpecs.swift
//  HackleNotificationServiceTests
//

import Quick
import Nimble
import Foundation
import UserNotifications
@testable import HackleNotificationService

class HackleNotificationServiceSpecs: QuickSpec {
    override class func spec() {
        func content(userInfo: [AnyHashable: Any]) -> UNMutableNotificationContent {
            let content = UNMutableNotificationContent()
            content.title = "title"
            content.userInfo = userInfo
            return content
        }

        func request(userInfo: [AnyHashable: Any]) -> UNNotificationRequest {
            UNNotificationRequest(identifier: "id", content: content(userInfo: userInfo), trigger: nil)
        }

        func hacklePayload() -> [AnyHashable: Any] {
            ["hackle": ["workspaceId": 123, "environmentId": 456]]
        }

        describe("payload parsing") {
            it("returns false and does not call back when hackle key is missing") {
                var callCount = 0
                let handled = HackleNotificationService.handleRichNotification(notificationContent: content(userInfo: ["foo": "bar"])) { _ in
                    callCount += 1
                }
                expect(handled).to(beFalse())
                expect(callCount).to(equal(0))
            }

            it("returns false when workspaceId is missing") {
                var callCount = 0
                let handled = HackleNotificationService.handleRichNotification(notificationContent: content(userInfo: ["hackle": ["environmentId": 456]])) { _ in
                    callCount += 1
                }
                expect(handled).to(beFalse())
                expect(callCount).to(equal(0))
            }

            it("returns false when environmentId is missing") {
                var callCount = 0
                let handled = HackleNotificationService.handleRichNotification(notificationContent: content(userInfo: ["hackle": ["workspaceId": 123]])) { _ in
                    callCount += 1
                }
                expect(handled).to(beFalse())
                expect(callCount).to(equal(0))
            }

            it("returns false when workspaceId is a Bool") {
                var callCount = 0
                let handled = HackleNotificationService.handleRichNotification(notificationContent: content(userInfo: ["hackle": ["workspaceId": true as Any, "environmentId": 456]])) { _ in
                    callCount += 1
                }
                expect(handled).to(beFalse())
                expect(callCount).to(equal(0))
            }

            it("returns false when workspaceId is a numeric string") {
                var callCount = 0
                let handled = HackleNotificationService.handleRichNotification(notificationContent: content(userInfo: ["hackle": ["workspaceId": "123", "environmentId": 456]])) { _ in
                    callCount += 1
                }
                expect(handled).to(beFalse())
                expect(callCount).to(equal(0))
            }

            it("returns true and calls back once keeping attachments when imageUrl is missing") {
                let notificationContent = content(userInfo: hacklePayload())
                var received: [UNNotificationContent] = []
                let handled = HackleNotificationService.handleRichNotification(notificationContent: notificationContent) { result in
                    received.append(result)
                }
                expect(handled).to(beTrue())
                expect(received.count).toEventually(equal(1), timeout: .seconds(5))
                expect(received.first?.attachments).to(beEmpty())
                expect(received.first?.title).to(equal("title"))
            }
        }

        describe("public functions") {
            it("handleRichNotification(request:contentHandler:) returns true and calls back once for a hackle push") {
                var callCount = 0
                let handled = HackleNotificationService.handleRichNotification(request: request(userInfo: hacklePayload())) { _ in
                    callCount += 1
                }
                expect(handled).to(beTrue())
                expect(callCount).toEventually(equal(1), timeout: .seconds(5))
            }

            it("handleRichNotification(notificationContent:contentHandler:) returns true and calls back once for a hackle push") {
                var callCount = 0
                let handled = HackleNotificationService.handleRichNotification(notificationContent: content(userInfo: hacklePayload())) { _ in
                    callCount += 1
                }
                expect(handled).to(beTrue())
                expect(callCount).toEventually(equal(1), timeout: .seconds(5))
            }

            it("resolveRichNotificationContent(request:completion:) returns true and calls back once for a hackle push") {
                var callCount = 0
                let handled = HackleNotificationService.resolveRichNotificationContent(request: request(userInfo: hacklePayload())) { _ in
                    callCount += 1
                }
                expect(handled).to(beTrue())
                expect(callCount).toEventually(equal(1), timeout: .seconds(5))
            }

            it("resolveRichNotificationContent(notificationContent:completion:) returns true and calls back once for a hackle push") {
                var callCount = 0
                let handled = HackleNotificationService.resolveRichNotificationContent(notificationContent: content(userInfo: hacklePayload())) { _ in
                    callCount += 1
                }
                expect(handled).to(beTrue())
                expect(callCount).toEventually(equal(1), timeout: .seconds(5))
            }
        }
    }
}
