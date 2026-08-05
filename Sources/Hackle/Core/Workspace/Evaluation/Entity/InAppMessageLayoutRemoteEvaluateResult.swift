import Foundation

final class InAppMessageLayoutRemoteEvaluateResult: InAppMessageLayoutEvaluateResult, InAppMessage, RemoteEvaluateResult, @unchecked Sendable {

    let id: InAppMessage.Id
    let key: InAppMessage.Key
    let order: Int64
    let period: InAppMessage.Period
    let timetable: InAppMessage.Timetable
    let eventTrigger: InAppMessage.EventTrigger
    let evaluateContext: InAppMessage.EvaluateContext
    let messageContext: InAppMessage.MessageContext
    let references: [Entity]

    init(
        id: InAppMessage.Id,
        key: InAppMessage.Key,
        order: Int64,
        period: InAppMessage.Period,
        timetable: InAppMessage.Timetable,
        eventTrigger: InAppMessage.EventTrigger,
        evaluateContext: InAppMessage.EvaluateContext,
        messageContext: InAppMessage.MessageContext,
        message: InAppMessage.Message,
        reason: String,
        references: [Entity]
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
        super.init(reason: reason, message: message)
    }

    func toEvaluation() -> InAppMessageLayoutEvaluation {
        InAppMessageLayoutEvaluation(entity: self, result: self)
    }
}
