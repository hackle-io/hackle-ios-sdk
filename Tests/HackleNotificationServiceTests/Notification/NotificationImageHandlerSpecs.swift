//
//  NotificationImageHandlerSpecs.swift
//  HackleNotificationServiceTests
//

import Quick
import Nimble
import Foundation
import UserNotifications
@testable import HackleNotificationService

class NotificationImageHandlerSpecs: QuickSpec {
    override class func spec() {
        describe("NotificationImageHandler") {
            it("should return a attachment on download success") {
                let imageUrl = "https://raw.githubusercontent.com/hackle-io/hackle-ios-sdk/refs/heads/master/Sources/Hackle/Resources/Images/hackle_banner.png"
                let notificationData = NotificationData(imageUrl: imageUrl)
                var resultAttachment: UNNotificationAttachment?

                waitUntil(timeout: .seconds(10)) { done in
                    NotificationImageHandler.handlePushImage(notificationData: notificationData) { attachment in
                        resultAttachment = attachment
                        done()
                    }
                }

                expect(resultAttachment).toNot(beNil())
            }

            it("should return a nil attachment when download is unsuccessful") {
                let imageUrl = "https://notexistfake/notfound.jpg"
                let notificationData = NotificationData(imageUrl: imageUrl)
                var resultAttachment: UNNotificationAttachment?

                waitUntil(timeout: .seconds(10)) { done in
                    NotificationImageHandler.handlePushImage(notificationData: notificationData) { attachment in
                        resultAttachment = attachment
                        done()
                    }
                }

                expect(resultAttachment).to(beNil())
            }

            it("should return a nil attachment for an empty URL") {
                let notificationData = NotificationData(imageUrl: "")
                var resultAttachment: UNNotificationAttachment?

                waitUntil { done in
                    NotificationImageHandler.handlePushImage(notificationData: notificationData) { attachment in
                        resultAttachment = attachment
                        done()
                    }
                }

                expect(resultAttachment).to(beNil())
            }

            it("should return a nil attachment for an nil URL") {
                let notificationData = NotificationData(imageUrl: nil)
                var resultAttachment: UNNotificationAttachment?

                waitUntil { done in
                    NotificationImageHandler.handlePushImage(notificationData: notificationData) { attachment in
                        resultAttachment = attachment
                        done()
                    }
                }

                expect(resultAttachment).to(beNil())
            }

            it("should return a nil attachment when the response is not a supported image type") {
                let notificationData = NotificationData(imageUrl: "https://www.hackle.io")
                var resultAttachment: UNNotificationAttachment?

                waitUntil(timeout: .seconds(10)) { done in
                    NotificationImageHandler.handlePushImage(notificationData: notificationData) { attachment in
                        resultAttachment = attachment
                        done()
                    }
                }

                expect(resultAttachment).to(beNil())
            }
        }
    }
}
