import Foundation

protocol UserEventDedupDeterminer {
    func isDedupTarget(event: UserEvent) -> Bool
}
