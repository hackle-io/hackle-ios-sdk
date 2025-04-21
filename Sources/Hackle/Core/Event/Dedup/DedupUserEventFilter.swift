import Foundation

class DedupUserEventFilter: UserEventFilter {
    private let eventDedupDeterminer: UserEventDedupDeterminer

    init(eventDedupDeterminer: UserEventDedupDeterminer) {
        self.eventDedupDeterminer = eventDedupDeterminer
    }

    func check(event: UserEvent) -> UserEventFilterResult {
        let isDedupTarget = eventDedupDeterminer.isDedupTarget(event: event)
        if isDedupTarget {
            return .block
        } else {
            return .pass
        }
    }
    
    func filter(event: UserEvent) -> UserEvent {
        return event
    }
}
