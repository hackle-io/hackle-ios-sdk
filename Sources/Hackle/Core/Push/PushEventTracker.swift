import Foundation

protocol PushEventTracker {
    func trackPushToken(pushToken: PushToken, user: User, timestamp: Date)
}

class DefaultPushEventTracker: PushEventTracker {

    private let userManager: UserManager
    private let core: HackleCore

    init(userManager: UserManager, core: HackleCore) {
        self.userManager = userManager
        self.core = core
    }

    func trackPushToken(pushToken: PushToken, user: User, timestamp: Date) {
        let event = Event.builder(PushEventKey.pushToken.rawValue)
            .property("provider_type", pushToken.providerType.rawValue)
            .property("token", pushToken.value)
            .build()
        track(event: event, user: user, timestamp: timestamp)
    }

    private func track(event: Event, user: User, timestamp: Date) {
        let hackleUser = userManager.toHackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
    }
}

enum PushEventKey: String, CaseIterable {
    case pushToken = "$push_token"
    case pushClick = "$push_click"

    static func isPushEvent(event: UserEvent) -> Bool {
        guard let trackEvent = event as? UserEvents.Track else {
            return false
        }
        return PushEventKey.allCases.contains { key in
            trackEvent.event.key == key.rawValue
        }
    }
}
