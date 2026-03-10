import Foundation

class OptOutUserEventFilter: UserEventFilter {

    private let optOutManager: OptOutManager

    init(optOutManager: OptOutManager) {
        self.optOutManager = optOutManager
    }

    func check(event: UserEvent) -> UserEventFilterResult {
        if optOutManager.isOptOutTracking {
            return .block
        } else {
            return .pass
        }
    }
}
