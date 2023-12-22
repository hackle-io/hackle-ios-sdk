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
            .property("provier_type", NotificationProviderType.ApplePushNotificationService.rawValue)
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
            .build()
    }
}

extension NotificationEntity {
    func toTrackEvent() -> Event {
        return Event.builder("$push_click")
            .property("push_message_id", pushMessageId)
            .property("push_message_key", pushMessageKey)
            .property("push_message_execution_id", pushMessageExecutionId)
            .property("push_message_delivery_id", pushMessageDeliveryId)
            .build()
    }
}
