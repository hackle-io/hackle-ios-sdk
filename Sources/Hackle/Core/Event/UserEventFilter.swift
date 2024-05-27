import Foundation

protocol UserEventFilter {
    func check(event: UserEvent) -> UserEventFilterResult
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
