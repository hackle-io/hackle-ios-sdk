import Foundation

protocol UserEventFilter {
    func check(event: UserEvent) -> UserEventFilterResult
    func filter(event: UserEvent) -> UserEvent
}

extension UserEventFilter {
    func isBlock(event: UserEvent) -> Bool {
        check(event: event).isBlock
    }
}

enum UserEventFilterResult {
    case block
    case pass

    var isBlock: Bool {
        self == .block
    }
}
