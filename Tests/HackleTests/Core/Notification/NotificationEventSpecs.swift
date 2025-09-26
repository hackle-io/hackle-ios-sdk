import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class NotificationEventSpecs: QuickSpec {
    override func spec() {
        it("register push token event") {
            let event = RegisterPushTokenEvent(token: "abcd1234")
                .toTrackEvent()
            expect(event.key) == "$push_token"
            expect(event.properties?["provider_type"] as? String) == "APN"
            expect(event.properties?["token"] as? String) == "abcd1234"
        }
        it("notification data to event") {
            let data = NotificationData(
                workspaceId: 123,
                environmentId: 456,
                pushMessageId: 1,
                pushMessageKey: 2,
                pushMessageExecutionId: 3,
                pushMessageDeliveryId: 4,
                showForeground: true,
                imageUrl: "foo://bar/image",
                clickAction: NotificationClickAction.deepLink,
                link: "foo://bar",
                journeyId: 5,
                journeyKey: 6,
                journeyNodeId: 7,
                campaignType: "JOURNEY",
                debug: true
            )
            let event = data.toTrackEvent()
            expect(event.key) == "$push_click"
            expect(event.properties?["push_message_id"].asIntOrNil()) == 1
            expect(event.properties?["push_message_key"].asIntOrNil()) == 2
            expect(event.properties?["push_message_execution_id"].asIntOrNil()) == 3
            expect(event.properties?["push_message_delivery_id"].asIntOrNil()) == 4
            expect(event.properties?["campaign_type"] as? String) == "JOURNEY"
            expect(event.properties?["debug"] as? Bool) == true
        }
        it("notification history entity to event") {
            let timestamp = Date()
            let entity = NotificationHistoryEntity(
                historyId: 0,
                workspaceId: 1,
                environmentId: 2,
                pushMessageId: 3,
                pushMessageKey: 4,
                pushMessageExecutionId: 5,
                pushMessageDeliveryId: 6,
                timestamp: timestamp,
                debug: true,
                journeyId: 7,
                journeyKey: 8,
                journeyNodeId: 9,
                campaignType: "PUSH_MESSAGE"
            )
            let event = entity.toTrackEvent()
            expect(event.key) == "$push_click"
            expect(event.properties?["push_message_id"].asIntOrNil()) == 3
            expect(event.properties?["push_message_key"].asIntOrNil()) == 4
            expect(event.properties?["push_message_execution_id"].asIntOrNil()) == 5
            expect(event.properties?["push_message_delivery_id"].asIntOrNil()) == 6
            expect(event.properties?["campaign_type"] as? String) == "PUSH_MESSAGE"
            expect(event.properties?["debug"] as? Bool) == true
        }
    }
}
