import XCTest
import UIKit
@testable import Hackle

final class NotificationHandlerPendingUrlTests: XCTestCase {
    private let url = URL(string: "https://example.com/promo")!

    @MainActor
    func testUnmatchedLinkBeforeInitializationIsDeliveredAfterForwardAllHandlerInstalled() async throws {
        let sut = Sut()
        let activityHandler = MockUserActivityHandler()
        activityHandler.sceneSupported = true
        let configured = ApplicationUrlHandler(
            policy: .forwardAll,
            entitlements: { Entitlements(applinks: []) },
            userActivityHandler: activityHandler
        )

        try await sut.click(url)
        XCTAssertTrue(activityHandler.sceneUrls.isEmpty)

        sut.initialize(HackleUrlDispatcher(urlHandler: configured))

        XCTAssertNil(sut.storage.pendingUrl)
        XCTAssertTrue(configured.hasPendingUrl)
        XCTAssertTrue(activityHandler.sceneUrls.isEmpty)

        activateTwice()
        XCTAssertEqual(activityHandler.sceneUrls, [url])
        XCTAssertFalse(configured.hasPendingUrl)
    }

    @MainActor
    func testDrainOpensLastLinkOnce() async throws {
        let sut = Sut()
        let urls = (1...3).map { URL(string: "https://example.com/\($0)")! }
        for url in urls {
            try await sut.click(url)
        }

        let installed = MockUrlHandler()
        sut.initialize(HackleUrlDispatcher(urlHandler: installed))
        XCTAssertEqual(installed.openedUrls, [urls.last!])
        XCTAssertEqual(installed.channels, [.push])
        XCTAssertNil(sut.storage.drain())
    }

    @MainActor
    func testClickAfterInitializationGoesDirectlyToDispatcher() async throws {
        let sut = Sut()
        let installed = MockUrlHandler()
        sut.initialize(HackleUrlDispatcher(urlHandler: installed))

        sut.notificationHandler.handlePushClickAction(notificationData: notificationData())
        try await waitUntil { installed.openCallCount == 1 }
        XCTAssertEqual(installed.openedUrls, [url])
        XCTAssertEqual(installed.channels, [.push])
        XCTAssertNil(sut.storage.pendingUrl)
    }

    @MainActor
    func testTapBeforeInitializationIsStoredEvenWithDelegateAndDeliveredOnDrain() async throws {
        let sut = Sut()
        let delegate = MockHackleDelegate()
        let custom = URL(string: "myapp://home")!

        try await sut.click(custom)
        XCTAssertEqual(sut.storage.pendingUrl, custom)
        XCTAssertTrue(delegate.contexts.isEmpty)

        sut.initialize(HackleUrlDispatcher(urlHandler: DelegateUrlHandler(delegate: delegate)))
        XCTAssertEqual(delegate.contexts.map(\.url), [custom])
        XCTAssertEqual(delegate.contexts.first?.channel, .push)
        XCTAssertNil(sut.storage.pendingUrl)
    }

    @MainActor
    func testPendingCustomSchemeOpensOnDefaultHandlerWithoutDelegate() async throws {
        let sut = Sut()
        let custom = URL(string: "myapp://home")!
        try await sut.click(custom)

        let installed = MockUrlHandler()
        sut.initialize(HackleUrlDispatcher(urlHandler: installed))
        XCTAssertEqual(installed.openedUrls, [custom])
    }

    @MainActor
    func testPendingUrlHoldsCustomSchemeAndDropsSchemelessLinks() async throws {
        let sut = Sut()
        let custom = URL(string: "hackle://example.com/x")!
        try await sut.click(custom)

        sut.notificationHandler.handlePushClickAction(notificationData: notificationData(link: "example.com"))
        await Task.yield()
        XCTAssertEqual(sut.storage.pendingUrl, custom)

        let home = URL(string: "myapp://home")!
        try await sut.click(home)
        sut.notificationHandler.handlePushClickAction(notificationData: notificationData(link: "example.com"))
        await Task.yield()
        XCTAssertEqual(sut.storage.pendingUrl, home)
    }

    @MainActor
    func testSchemelessLinkAfterInitializationIsDropped() async throws {
        let sut = Sut()
        let installed = MockUrlHandler()
        sut.initialize(HackleUrlDispatcher(urlHandler: installed))

        sut.notificationHandler.handlePushClickAction(notificationData: notificationData(link: "example.com"))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(installed.openCallCount, 0)
        XCTAssertNil(sut.storage.pendingUrl)
    }

    @MainActor
    private final class Sut {
        let storage: PendingUrlStorage
        let current: AtomicReference<HackleUrlDispatcher?>
        let notificationHandler: NotificationHandler

        init() {
            let storage = PendingUrlStorage()
            let current = AtomicReference<HackleUrlDispatcher?>(value: nil)
            self.storage = storage
            self.current = current
            self.notificationHandler = NotificationHandler(
                dispatchQueue: DispatchQueue(label: "test.pending.push"),
                storage: storage,
                urlDispatcher: { current.get() }
            )
        }

        func initialize(_ dispatcher: HackleUrlDispatcher) {
            current.set(newValue: dispatcher)
            if let url = storage.drain() {
                dispatcher.open(url: url, channel: .push)
            }
        }

        func click(_ url: URL) async throws {
            notificationHandler.handlePushClickAction(notificationData: NotificationHandlerPendingUrlTests.data(link: url.absoluteString))
            let deadline = Date().addingTimeInterval(3)
            while storage.pendingUrl != url && Date() < deadline {
                try await Task.sleep(nanoseconds: 1_000_000)
            }
            XCTAssertEqual(storage.pendingUrl, url)
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

    @MainActor
    private func activateTwice() {
        for _ in 0..<2 {
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        }
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
