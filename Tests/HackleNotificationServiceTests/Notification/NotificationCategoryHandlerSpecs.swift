//
//  NotificationCategoryHandlerSpecs.swift
//  HackleNotificationServiceTests
//

import Quick
import Nimble
import Foundation
import UserNotifications
@testable import HackleNotificationService

private func makeCategory(identifier: String, titles: [String]) -> UNNotificationCategory {
    let actions = titles.enumerated().map { index, title in
        UNNotificationAction(identifier: "action_\(index)", title: title, options: [])
    }
    return UNNotificationCategory(identifier: identifier, actions: actions, intentIdentifiers: [], options: [])
}

class NotificationCategoryHandlerSpecs: QuickSpec {
    override class func spec() {
        func existing() -> UNNotificationCategory {
            makeCategory(identifier: "app_category", titles: ["x"])
        }

        describe("category") {
            it("builds actions in item order") {
                let data = NotificationData(imageUrl: nil, categoryId: "hackle_a", buttonTitles: ["수신거부", "열기"])

                let category = NotificationCategoryHandler.category(notificationData: data)

                expect(category?.identifier) == "hackle_a"
                expect(category?.actions.map(\.identifier)) == ["hackle_action_0", "hackle_action_1"]
                expect(category?.actions.map(\.title)) == ["수신거부", "열기"]
                expect(category?.actions.allSatisfy { $0.options == [.foreground] }) == true
                expect(category?.intentIdentifiers.isEmpty) == true
                expect(category?.options) == []
            }

            it("returns nil") {
                let nilId = NotificationData(imageUrl: nil, categoryId: nil, buttonTitles: ["a"])
                let emptyId = NotificationData(imageUrl: nil, categoryId: "", buttonTitles: ["a"])
                let noButtons = NotificationData(imageUrl: nil, categoryId: "hackle_a", buttonTitles: [])

                expect(NotificationCategoryHandler.category(notificationData: nilId)).to(beNil())
                expect(NotificationCategoryHandler.category(notificationData: emptyId)).to(beNil())
                expect(NotificationCategoryHandler.category(notificationData: noButtons)).to(beNil())
            }
        }

        describe("merge") {
            it("keeps other categories") {
                let merged = NotificationCategoryHandler.merge(
                    categories: [existing()],
                    category: makeCategory(identifier: "hackle_a", titles: ["a"])
                )

                expect(Set(merged.map(\.identifier))) == ["app_category", "hackle_a"]
            }

            it("replaces a category with the same identifier") {
                let merged = NotificationCategoryHandler.merge(
                    categories: [makeCategory(identifier: "hackle_a", titles: ["a"])],
                    category: makeCategory(identifier: "hackle_a", titles: ["b"])
                )

                let matched = merged.filter { $0.identifier == "hackle_a" }
                expect(matched.count) == 1
                expect(matched.first?.actions.map(\.title)) == ["b"]
            }
        }

        describe("handlePushCategory") {
            it("skips registration when there are no buttons") {
                var results: [String?] = []

                NotificationCategoryHandler.handlePushCategory(notificationData: NotificationData(imageUrl: nil)) { categoryId in
                    results.append(categoryId)
                }

                expect(results) == [nil]
            }
        }
    }
}
