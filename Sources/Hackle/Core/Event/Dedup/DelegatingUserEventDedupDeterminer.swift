import Foundation


class DelegatingUserEventDedupDeterminer: UserEventDedupDeterminer {

    private let determiners: [any CachedUserEventDedupDeterminer]

    init(determiners: [any CachedUserEventDedupDeterminer]) {
        self.determiners = determiners
    }

    func isDedupTarget(event: UserEvent) -> Bool {
        guard let determiner = determiners.first(where: { determiner in determiner.support(event: event) }) else {
            return false
        }
        return determiner.isDedupTarget(event: event)
    }
}
