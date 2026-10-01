import Foundation
import Quick
import Nimble
@testable import Hackle


/// Stress spec for `NotificationHandler.setUrlHandler` vs push click read race regression.
/// Run under Thread Sanitizer to verify no access race is reported.
class NotificationHandlerRaceSpecs: QuickSpec {
    override class func spec() {

        it("concurrent setUrlHandler and push click deliver every click to a live handler") {
            let initial = MockUrlHandler()
            let handler = NotificationHandler(
                dispatchQueue: DispatchQueue(label: "test.race.queue"),
                urlHandler: initial
            )
            let replacements = (0..<8).map { _ in MockUrlHandler() }
            let writerCount = 4
            let iterations = 2_000
            let pushCount = 500
            let data = NotificationData(
                workspaceId: 123,
                environmentId: 456,
                pushMessageId: 1,
                pushMessageKey: 2,
                pushMessageExecutionId: 3,
                pushMessageDeliveryId: 4,
                showForeground: true,
                imageUrl: nil,
                clickAction: .deepLink,
                link: "https://www.hackle.io",
                journeyId: nil,
                journeyKey: nil,
                journeyNodeId: nil,
                campaignType: "JOURNEY",
                debug: true
            )

            let group = DispatchGroup()
            for w in 0..<writerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<iterations {
                        handler.setUrlHandler(replacements[(w + i) % replacements.count])
                    }
                }
            }

            for _ in 0..<pushCount {
                handler.handlePushClickAction(notificationData: data)
            }

            group.wait()

            let handlers = [initial] + replacements
            expect(handlers.map { $0.openCallCount }.reduce(0, +))
                .toEventually(equal(pushCount), timeout: .seconds(10))
        }
    }
}
