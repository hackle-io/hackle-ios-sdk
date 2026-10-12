import Foundation
import UIKit
import Quick
import Nimble
@testable import Hackle


/// Stress spec for url handler installation concurrent with push click routing.
/// Run under Thread Sanitizer to verify no access race is reported.
class NotificationHandlerRaceSpecs: QuickSpec {
    override class func spec() {

        it("installing the url handler concurrently with push clicks never duplicates or strands a link") {
            let pendingHandler = PendingUrlHandler()
            let handler = NotificationHandler(
                dispatchQueue: DispatchQueue(label: "test.race.queue"),
                urlHandler: pendingHandler
            )
            let installed = MockUrlHandler()
            let writerCount = 4
            let clicksPerWriter = 25
            let total = writerCount * clicksPerWriter
            let sentinel = URL(string: "https://www.hackle.io/sentinel")!

            func data(_ link: String) -> NotificationData {
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

            waitUntil(timeout: .seconds(30)) { done in
                let group = DispatchGroup()
                for w in 0..<writerCount {
                    DispatchQueue.global(qos: .utility).async(group: group) {
                        for i in 0..<clicksPerWriter {
                            handler.handlePushClickAction(notificationData: data("https://www.hackle.io/\(w * clicksPerWriter + i)"))
                        }
                    }
                }
                Task { @MainActor in
                    handler.setUrlHandler(installed)
                }

                group.notify(queue: .main) {
                    Task { @MainActor in
                        // Every click task enqueued above runs before this sentinel on the MainActor.
                        handler.handlePushClickAction(notificationData: data(sentinel.absoluteString))
                        let deadline = Date().addingTimeInterval(20)
                        while !installed.openedUrls.contains(sentinel) && Date() < deadline {
                            await Task.yield()
                        }
                        let opened = installed.openedUrls
                        expect(opened.last) == sentinel
                        expect(Set(opened).count) == opened.count
                        expect(opened.count) >= 2
                        expect(opened.count) <= total + 1
                        expect(pendingHandler.pendingUrl).to(beNil())
                        done()
                    }
                }
            }
        }
    }
}
