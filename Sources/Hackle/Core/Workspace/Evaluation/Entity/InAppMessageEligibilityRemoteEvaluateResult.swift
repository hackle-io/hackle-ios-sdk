import Foundation

final class InAppMessageEligibilityRemoteEvaluateResult: InAppMessageEligibilityEvaluateResult, InAppMessage, RemoteEvaluateResult, @unchecked Sendable {

    let id: InAppMessage.Id
    let key: InAppMessage.Key
    let order: Int64
    let period: InAppMessage.Period
    let timetable: InAppMessage.Timetable
    let eventTrigger: InAppMessage.EventTrigger
    let evaluateContext: InAppMessage.EvaluateContext
    let messageContext: InAppMessage.MessageContext
    let references: [Entity]
    let layout: InAppMessageLayoutRemoteEvaluateResult

    init(
        id: InAppMessage.Id,
        key: InAppMessage.Key,
        order: Int64,
        period: InAppMessage.Period,
        timetable: InAppMessage.Timetable,
        eventTrigger: InAppMessage.EventTrigger,
        evaluateContext: InAppMessage.EvaluateContext,
        messageContext: InAppMessage.MessageContext,
        isEligible: Bool,
        reason: String,
        references: [Entity],
        layout: InAppMessageLayoutRemoteEvaluateResult
    ) {
        self.id = id
        self.key = key
        self.order = order
        self.period = period
        self.timetable = timetable
        self.eventTrigger = eventTrigger
        self.evaluateContext = evaluateContext
        self.messageContext = messageContext
        self.references = references
        self.layout = layout
        super.init(reason: reason, isEligible: isEligible)
    }

    func toEvaluation() -> Evaluation {
        InAppMessageEligibilityEvaluation(entity: self, result: self)
    }
}
