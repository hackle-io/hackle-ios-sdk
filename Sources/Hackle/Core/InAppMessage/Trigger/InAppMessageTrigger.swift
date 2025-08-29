import Foundation

class InAppMessageTrigger {
    let inAppMessage: InAppMessage
    let reason: String
    let event: UserEvents.Track

    init(inAppMessage: InAppMessage, reason: String, event: UserEvents.Track) {
        self.inAppMessage = inAppMessage
        self.reason = reason
        self.event = event
    }
}

extension InAppMessageTrigger: CustomStringConvertible {
    var description: String {
        "InAppMessageTrigger(inAppMessage: \(inAppMessage), reason: \(reason), insertId: \(event.insertId), timestamp: \(event.timestamp), user: \(event.user.identifiers), event=\(event.event.key))"
    }
}
