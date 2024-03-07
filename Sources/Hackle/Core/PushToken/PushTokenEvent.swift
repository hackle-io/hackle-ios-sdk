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
            .property("provider_type", "APN")
            .property("token", token)
            .build()
    }
}
