import XCTest
import UIKit
@testable import Hackle

final class NotificationHandlerPendingUrlTests: XCTestCase {
    private let url = URL(string: "https://example.com/promo")!

    @MainActor
    func testLinkBeforeInitializationIsNotHeldByDefault() async throws {
        let sut = Sut()
        sut.notificationHandler.handlePushClickAction(notificationData: notificationData())
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNil(sut.storage.pendingUrl)

        let installed = MockUrlHandler()
        sut.initialize(HackleUrlDispatcher(defaultHandler: installed))
        XCTAssertEqual(installed.openCallCount, 0)
    }

    @MainActor
    func testClickAfterInitializationGoesDirectlyToDispatcher() async throws {
        let sut = Sut()
        let installed = MockUrlHandler()
        sut.initialize(HackleUrlDispatcher(defaultHandler: installed))

        sut.notificationHandler.handlePushClickAction(notificationData: notificationData())
        try await waitUntil { installed.openCallCount == 1 }
        XCTAssertEqual(installed.openedUrls, [url])
        XCTAssertEqual(installed.channels, [.push])
        XCTAssertNil(sut.storage.pendingUrl)
    }

    @MainActor
    func testSchemelessLinkAfterInitializationIsDropped() async throws {
        let sut = Sut()
        let installed = MockUrlHandler()
        sut.initialize(HackleUrlDispatcher(defaultHandler: installed))

        sut.notificationHandler.handlePushClickAction(notificationData: notificationData(link: "example.com"))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(installed.openCallCount, 0)
        XCTAssertNil(sut.storage.pendingUrl)
    }

    @MainActor
    private final class Sut {
        let notificationHandler = NotificationHandler(dispatchQueue: DispatchQueue(label: "test.pending.push"))

        var storage: PendingUrlStorage {
            notificationHandler.storage
        }

        func initialize(_ dispatcher: HackleUrlDispatcher) {
            notificationHandler.setUrlDispatcher(dispatcher)
        }
    }

    @MainActor
    private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(3)
        while !condition() && Date() < deadline {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        XCTAssertTrue(condition())
    }

    private func notificationData(link: String? = nil) -> NotificationData {
        Self.data(link: link ?? url.absoluteString)
    }

    fileprivate static func data(link: String) -> NotificationData {
        NotificationData(
            workspaceId: 123,
            environmentId: 456,
            pushMessageId: 1,
            pushMessageKey: 2,
            pushMessageExecutionId: 3,
            pushMessageDeliveryId: 4,
            showForeground: true,
            imageUrl: nil,
            clickAction: .deepLink,
            link: link,
            journeyId: nil,
            journeyKey: nil,
            journeyNodeId: nil,
            campaignType: "JOURNEY",
            debug: true
        )
    }
}
