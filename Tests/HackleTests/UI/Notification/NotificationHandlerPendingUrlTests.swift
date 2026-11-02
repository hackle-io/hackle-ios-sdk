import XCTest
import UIKit
@testable import Hackle

final class NotificationHandlerPendingUrlTests: XCTestCase {
    private let url = URL(string: "https://example.com/promo")!

    @MainActor
    func testUnmatchedLinkBeforeInitializationIsDeliveredAfterForwardAllHandlerInstalled() async throws {
        let pendingHandler = PendingUrlHandler()
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.pending.push"),
            urlHandler: pendingHandler
        )
        let activityHandler = MockUserActivityHandler()
        activityHandler.sceneSupported = true
        let configured = ApplicationUrlHandler(
            policy: .forwardAll,
            entitlements: { Entitlements(applinks: []) },
            userActivityHandler: activityHandler
        )

        notificationHandler.handlePushClickAction(notificationData: notificationData())
        try await waitUntil { pendingHandler.pendingUrl == self.url }
        XCTAssertTrue(activityHandler.sceneUrls.isEmpty)

        notificationHandler.setUrlHandler(configured)
        XCTAssertNil(pendingHandler.pendingUrl)
        XCTAssertTrue(configured.hasPendingUrl)
        XCTAssertTrue(activityHandler.sceneUrls.isEmpty)

        activateTwice()
        XCTAssertEqual(activityHandler.sceneUrls, [url])
        XCTAssertFalse(configured.hasPendingUrl)
        withExtendedLifetime(notificationHandler) {}
    }

    @MainActor
    func testDrainOpensLastLinkOnInstalledHandler() {
        let pendingHandler = PendingUrlHandler()
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.drain.last"),
            urlHandler: pendingHandler
        )
        let urls = (1...3).map { URL(string: "https://example.com/\($0)")! }
        for url in urls {
            pendingHandler.open(url: url)
        }
        XCTAssertEqual(pendingHandler.pendingUrl, urls.last)

        let installed = MockUrlHandler()
        notificationHandler.setUrlHandler(installed)
        XCTAssertEqual(installed.openedUrls, [urls.last!])
        XCTAssertNil(pendingHandler.pendingUrl)
    }

    @MainActor
    func testClickAfterInstallGoesDirectlyToInstalledHandler() async throws {
        let pendingHandler = PendingUrlHandler()
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.direct.push"),
            urlHandler: pendingHandler
        )
        let installed = MockUrlHandler()
        notificationHandler.setUrlHandler(installed)

        notificationHandler.handlePushClickAction(notificationData: notificationData())
        try await waitUntil { installed.openCallCount == 1 }
        XCTAssertEqual(installed.openedUrls, [url])
        XCTAssertNil(pendingHandler.pendingUrl)
    }

    @MainActor
    func testReplacingNonPendingHandlerDoesNotReplay() {
        let first = MockUrlHandler()
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.replace"),
            urlHandler: first
        )
        first.open(url: url)
        let second = MockUrlHandler()
        notificationHandler.setUrlHandler(second)
        XCTAssertEqual(second.openCallCount, 0)
    }

    @MainActor
    func testPendingHandlerHoldsCustomSchemeAndDropsSchemelessLinks() {
        let pendingHandler = PendingUrlHandler()
        let custom = URL(string: "hackle://example.com/x")!
        pendingHandler.open(url: custom)
        XCTAssertEqual(pendingHandler.pendingUrl, custom)
        pendingHandler.open(url: URL(string: "example.com")!)
        XCTAssertEqual(pendingHandler.pendingUrl, custom)
    }

    @MainActor
    func testDelegateReceivesPendingCustomSchemeOnInstall() async throws {
        let pendingHandler = PendingUrlHandler()
        let registry = HackleDelegateRegistry()
        let delegate = MockHackleDelegate()
        registry.setDelegate(delegate)
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.delegate.custom"),
            urlHandler: pendingHandler,
            delegateRegistry: registry
        )
        let custom = URL(string: "myapp://home")!

        notificationHandler.handlePushClickAction(notificationData: notificationData(link: custom.absoluteString))
        try await waitUntil { pendingHandler.pendingUrl == custom }
        XCTAssertTrue(delegate.contexts.isEmpty)

        let installed = MockUrlHandler()
        notificationHandler.setUrlHandler(installed)
        XCTAssertEqual(delegate.contexts.count, 1)
        XCTAssertEqual(delegate.contexts.first?.url, custom)
        XCTAssertEqual(delegate.contexts.first?.channel, .push)
        XCTAssertEqual(installed.openCallCount, 0)
        XCTAssertNil(pendingHandler.pendingUrl)
    }

    @MainActor
    func testPendingLinkGoesToDelegateRegisteredBeforeInstall() async throws {
        let pendingHandler = PendingUrlHandler()
        let registry = HackleDelegateRegistry()
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.delegate.late"),
            urlHandler: pendingHandler,
            delegateRegistry: registry
        )

        notificationHandler.handlePushClickAction(notificationData: notificationData())
        try await waitUntil { pendingHandler.pendingUrl == self.url }

        let delegate = MockHackleDelegate()
        registry.setDelegate(delegate)
        let installed = MockUrlHandler()
        notificationHandler.setUrlHandler(installed)
        XCTAssertEqual(delegate.contexts.map(\.url), [url])
        XCTAssertEqual(installed.openCallCount, 0)
    }

    @MainActor
    func testPendingCustomSchemeOpensOnInstalledHandlerWithoutDelegate() async throws {
        let pendingHandler = PendingUrlHandler()
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.no.delegate.custom"),
            urlHandler: pendingHandler,
            delegateRegistry: HackleDelegateRegistry()
        )
        let custom = URL(string: "myapp://home")!

        notificationHandler.handlePushClickAction(notificationData: notificationData(link: custom.absoluteString))
        try await waitUntil { pendingHandler.pendingUrl == custom }

        let installed = MockUrlHandler()
        notificationHandler.setUrlHandler(installed)
        XCTAssertEqual(installed.openedUrls, [custom])
    }

    @MainActor
    func testOnlyLastPendingLinkReachesDelegateOnce() {
        let pendingHandler = PendingUrlHandler()
        let registry = HackleDelegateRegistry()
        let delegate = MockHackleDelegate()
        registry.setDelegate(delegate)
        let notificationHandler = NotificationHandler(
            dispatchQueue: DispatchQueue(label: "test.delegate.last"),
            urlHandler: pendingHandler,
            delegateRegistry: registry
        )
        let urls = (1...3).map { URL(string: "https://example.com/\($0)")! }
        for url in urls {
            pendingHandler.open(url: url)
        }

        let installed = MockUrlHandler()
        notificationHandler.setUrlHandler(installed)
        XCTAssertEqual(delegate.contexts.map(\.url), [urls.last!])
        XCTAssertEqual(installed.openCallCount, 0)
    }

    @MainActor
    private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(3)
        while !condition() && Date() < deadline {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        XCTAssertTrue(condition())
    }

    @MainActor
    private func activateTwice() {
        for _ in 0..<2 {
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }

    private func notificationData(link: String? = nil) -> NotificationData {
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
            link: link ?? url.absoluteString,
            journeyId: nil,
            journeyKey: nil,
            journeyNodeId: nil,
            campaignType: "JOURNEY",
            debug: true
        )
    }
}
