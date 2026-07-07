import Foundation

class PropertiesEventTracker: UserListener {

    private let core: HackleCore
    private let eventProcessor: UserEventProcessor
    private let userManager: UserManager

    init(core: HackleCore, eventProcessor: UserEventProcessor, userManager: UserManager) {
        self.core = core
        self.eventProcessor = eventProcessor
        self.userManager = userManager
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        // nothing to do
    }

    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
        let event = operations.toEvent()
        let hackleUser = userManager.toHackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
        eventProcessor.flush()
    }
}
