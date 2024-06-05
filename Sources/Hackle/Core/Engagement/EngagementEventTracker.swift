import Foundation

class EngagementEventTracker: EngagementListener {

    static let ENGAGEMENT_EVENT_KEY = "$engagement"
    static let ENGAGEMENT_TIME_PROPERTY_KEY = "$engagement_time_ms"

    private let userManager: UserManager
    private let core: HackleCore

    init(userManager: UserManager, core: HackleCore) {
        self.userManager = userManager
        self.core = core
    }

    func onEngagement(engagement: Engagement, user: User, timestamp: Date) {
        let event = Event.builder(Self.ENGAGEMENT_EVENT_KEY)
            .property(Self.ENGAGEMENT_TIME_PROPERTY_KEY, engagement.duration.millis)
            .property(ScreenEventTracker.SCREEN_NAME_PROPERTY_KEY, engagement.screen.name)
            .property(ScreenEventTracker.SCREEN_CLASS_PROPERTY_KEY, engagement.screen.className)
            .build()
        let hackleUser = userManager.toHackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
    }
}
