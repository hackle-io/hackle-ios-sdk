import Foundation

class RegisterPushTokenEvent {
    let token: String
    init(token: String) {
        self.token = token
    }
}

extension RegisterPushTokenEvent {
    func toTrackEvent() -> Event {
        return Event.builder("$push_token")
            .property("provider_type", NotificationProviderType.apn.rawValue)
            .property("token", token)
            .build()
    }
}

extension NotificationData {
    func toTrackEvent() -> Event {
        return Event.builder("$push_click")
            .property("push_message_id", pushMessageId)
            .property("push_message_key", pushMessageKey)
            .property("push_message_execution_id", pushMessageExecutionId)
            .property("push_message_delivery_id", pushMessageDeliveryId)
            .property("journey_id", journeyId)
            .property("journey_key", journeyKey)
            .property("journey_node_id", journeyNodeId)
            .property("campaign_type", campaignType)
            .property("debug", debug)
            .build()
    }
}

extension NotificationHistoryEntity {
    func toTrackEvent() -> Event {
        return Event.builder("$push_click")
            .property("push_message_id", pushMessageId)
            .property("push_message_key", pushMessageKey)
            .property("push_message_execution_id", pushMessageExecutionId)
            .property("push_message_delivery_id", pushMessageDeliveryId)
            .property("journey_id", journeyId)
            .property("journey_key", journeyKey)
            .property("journey_node_id", journeyNodeId)
            .property("campaign_type", campaignType)
            .property("debug", debug)
            .build()
    }
}
