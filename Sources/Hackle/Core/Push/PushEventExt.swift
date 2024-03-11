import Foundation


extension PushToken {
    func toEvent() -> Event {
        Event.builder("$push_token")
            .property("provider_type", providerType.rawValue)
            .property("token", value)
            .build()
    }
}
