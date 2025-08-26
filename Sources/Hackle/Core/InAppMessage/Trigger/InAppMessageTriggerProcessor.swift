import Foundation

protocol InAppMessageTriggerProcessor {
    func process(event: UserEvent)
}

class DefaultInAppMessageTriggerProcessor: InAppMessageTriggerProcessor {
    private let determiner: InAppMessageTriggerDeterminer
    private let handler: InAppMessageTriggerHandler

    init(determiner: InAppMessageTriggerDeterminer, handler: InAppMessageTriggerHandler) {
        self.determiner = determiner
        self.handler = handler
    }

    func process(event: UserEvent) {
        do {
            guard let trigger = try determiner.determine(event: event) else {
                return
            }
            Log.debug("InAppMessage triggered: \(trigger)")

            handler.handle(trigger: trigger)
        } catch {
            Log.error("Failed to process InAppMessage event trigger: \(error)")
        }
    }
}
