import Foundation

class InAppMessageViewEventActionHandler: InAppMessageViewEventHandler {
    private let actorFactory: InAppMessageViewEventActorFactory

    init(actorFactory: InAppMessageViewEventActorFactory) {
        self.actorFactory = actorFactory
    }

    func supports(handleType: InAppMessageViewEventHandleType) -> Bool {
        return handleType == .action
    }

    func handle(view: InAppMessageView, event: InAppMessageViewEvent) {
        guard let actor = actorFactory.get(type: event.type) else {
            return
        }
        actor.action(view: view, event: event)
    }
}
