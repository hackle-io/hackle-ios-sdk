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

    var isTappable: Bool {
        switch evaluation.reason {
        case DecisionReason.IN_APP_MESSAGE_TARGET,
             DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET,
             DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED,
             DecisionReason.IN_APP_MESSAGE_HIDDEN:
            return true
        default:
            return false
        }
    }

    static func of(decisions: [(InAppMessage, InAppMessageEligibilityEvaluation)]) -> [HackleInAppMessageItem] {
        decisions
            .map { HackleInAppMessageItem(inAppMessage: $0.0, evaluation: $0.1) }
            .sorted { $0.inAppMessage.key > $1.inAppMessage.key }
    }
}
