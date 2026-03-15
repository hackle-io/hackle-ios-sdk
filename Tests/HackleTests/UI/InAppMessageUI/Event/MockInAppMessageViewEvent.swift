import Foundation
@testable import Hackle

struct MockInAppMessageViewEvent: InAppMessageViewEvent {
    let type: InAppMessageViewEventType
    let timestamp: Date

    init(type: InAppMessageViewEventType = .impression, timestamp: Date = Date()) {
        self.type = type
        self.timestamp = timestamp
    }
}
