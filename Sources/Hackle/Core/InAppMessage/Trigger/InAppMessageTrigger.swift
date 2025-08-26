import Foundation

class InAppMessageTrigger {
    let inAppMessage: InAppMessage
    let evaluation: InAppMessageEvaluation
    let event: UserEvents.Track

    init(inAppMessage: InAppMessage, evaluation: InAppMessageEvaluation, event: UserEvents.Track) {
        self.inAppMessage = inAppMessage
        self.evaluation = evaluation
        self.event = event
    }
}

extension InAppMessageTrigger: CustomStringConvertible {
    var description: String {
        "InAppMessageTrigger(inAppMessage: \(inAppMessage), evaluation: \(evaluation), insertId: \(event.insertId), timestamp: \(event.timestamp), user: \(event.user.identifiers), event=\(event.event.key))"
    }
}
