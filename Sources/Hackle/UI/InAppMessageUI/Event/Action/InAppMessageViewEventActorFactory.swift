import Foundation

protocol InAppMessageViewEventActorFactory {
    func get(type: InAppMessageViewEventType) -> InAppMessageViewEventActor?
}

class DefaultInAppMessageViewEventActorFactory: InAppMessageViewEventActorFactory {
    private let actors: [InAppMessageViewEventActor]

    init(actors: [InAppMessageViewEventActor]) {
        self.actors = actors
    }

    func get(type: InAppMessageViewEventType) -> InAppMessageViewEventActor? {
        actors.first { it in
            it.supports(type: type)
        }
    }
}
