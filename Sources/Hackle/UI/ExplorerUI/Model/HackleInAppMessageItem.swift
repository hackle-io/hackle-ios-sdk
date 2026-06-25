import Foundation

struct HackleInAppMessageItem {

    let inAppMessage: InAppMessage
    let evaluation: InAppMessageEligibilityEvaluation

    var keyLabel: String {
        "# \(inAppMessage.key)"
    }

    var descLabel: String {
        let eventKey = inAppMessage.eventTrigger.rules.first?.eventKey ?? ""
        return "\(inAppMessage.status.rawValue) | \(eventKey)"
    }

    var reasonLabel: String {
        evaluation.reason
    }

    var isEligible: Bool {
        evaluation.isEligible
    }

    static func of(decisions: [(InAppMessage, InAppMessageEligibilityEvaluation)]) -> [HackleInAppMessageItem] {
        decisions
            .map { HackleInAppMessageItem(inAppMessage: $0.0, evaluation: $0.1) }
            .sorted { $0.inAppMessage.key > $1.inAppMessage.key }
    }
}
