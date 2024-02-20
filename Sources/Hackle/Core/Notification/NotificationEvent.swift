import Foundation

extension NotificationData {
    func toTrackEvent() -> Event {
        return Event.builder("$push_click")
            .property("push_message_id", pushMessageId)
            .property("push_message_key", pushMessageKey)
            .property("push_message_execution_id", pushMessageExecutionId)
            .property("push_message_delivery_id", pushMessageDeliveryId)
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
            .property("debug", debug)
            .build()
    }
}
