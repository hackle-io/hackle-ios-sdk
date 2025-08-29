import Foundation

class InAppMessageManager: UserEventListener, UserListener {

    private let triggerProcessor: InAppMessageTriggerProcessor
    private let resetProcessor: InAppMessageResetProcessor

    init(triggerProcessor: InAppMessageTriggerProcessor, resetProcessor: InAppMessageResetProcessor) {
        self.triggerProcessor = triggerProcessor
        self.resetProcessor = resetProcessor
    }

    func onEvent(event: UserEvent) {
        triggerProcessor.process(event: event)
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        resetProcessor.process(oldUser: oldUser, newUser: newUser)
    }
}
