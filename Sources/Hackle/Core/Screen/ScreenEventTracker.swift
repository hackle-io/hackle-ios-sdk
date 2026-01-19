import Foundation

class ScreenEventTracker: ScreenListener {

    static let SCREEN_VIEW_EVENT_KEY = "$page_view"
    static let SCREEN_NAME_PROPERTY_KEY = "$page_name"
    static let SCREEN_CLASS_PROPERTY_KEY = "$page_class"
    static let PREVIOUS_SCREEN_NAME_PROPERTY_KEY = "$previous_page_name"
    static let PREVIOUS_SCREEN_CLASS_PROPERTY_KEY = "$previous_page_class"

    private let userManager: UserManager
    private let core: HackleCore

    init(userManager: UserManager, core: HackleCore) {
        self.userManager = userManager
        self.core = core
    }

    func onScreenStarted(previousScreen: Screen?, currentScreen: Screen, user: User, timestamp: Date) {
        let event = Event.builder(Self.SCREEN_VIEW_EVENT_KEY)
            .properties(currentScreen.properties)
            .property(Self.SCREEN_NAME_PROPERTY_KEY, currentScreen.name)
            .property(Self.SCREEN_CLASS_PROPERTY_KEY, currentScreen.className)
            .property(Self.PREVIOUS_SCREEN_NAME_PROPERTY_KEY, previousScreen?.name)
            .property(Self.PREVIOUS_SCREEN_CLASS_PROPERTY_KEY, previousScreen?.className)
            .build()
        let hackleUser = userManager.toHackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
    }

    func onScreenEnded(screen: Screen, user: User, timestamp: Date) {
        // do nothing
    }
}
