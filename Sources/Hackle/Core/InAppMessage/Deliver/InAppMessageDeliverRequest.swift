import Foundation

class InAppMessageDeliverRequest {
    let dispatchId: String
    let inAppMessageKey: InAppMessage.Key
    let identifiers: Identifiers
    let requestedAt: Date
    let reason: String
    let properties: [String: Any]

    init(
        dispatchId: String,
        inAppMessageKey: InAppMessage.Key,
        identifiers: Identifiers,
        requestedAt: Date,
        reason: String,
        properties: [String: Any]
    ) {
        self.dispatchId = dispatchId
        self.inAppMessageKey = inAppMessageKey
        self.identifiers = identifiers
        self.requestedAt = requestedAt
        self.reason = reason
        self.properties = properties
    }
}

extension InAppMessageDeliverRequest: CustomStringConvertible {
    var description: String {
        "InAppMessageDeliverRequest(dispatchId: \(dispatchId), inAppMessageKey: \(inAppMessageKey), identifiers: \(identifiers), requestedAt: \(requestedAt), reason: \(reason), properties: \(properties))"
    }

    static func of(request: InAppMessageScheduleRequest) -> InAppMessageDeliverRequest {
        return InAppMessageDeliverRequest(
            dispatchId: request.schedule.dispatchId,
            inAppMessageKey: request.schedule.inAppMessageKey,
            identifiers: request.schedule.identifiers,
            requestedAt: request.requestedAt,
            reason: request.schedule.reason,
            properties: PropertiesBuilder()
                .add("trigger_event_insert_id", request.schedule.eventBasedContext.insertId)
                .build()
        )
    }
}
