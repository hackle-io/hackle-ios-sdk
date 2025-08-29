import Foundation

protocol InAppMessageRecorder {
    func record(request: InAppMessagePresentRequest, response: InAppMessagePresentResponse)
}

class DefaultInAppMessageRecorder: InAppMessageRecorder {

    private static let STORE_MAX_SIZE = 100

    private let storage: InAppMessageImpressionStorage

    init(storage: InAppMessageImpressionStorage) {
        self.storage = storage
    }

    func record(request: InAppMessagePresentRequest, response: InAppMessagePresentResponse) {
        if (request.reason == DecisionReason.OVERRIDDEN) {
            return
        }

        do {
            try doRecord(request: request)
            Log.debug("InAppMessage recorded: \(request)")
        } catch {
            Log.error("Failed to record InAppMessageImpression: \(error)")
        }
    }

    private func doRecord(request: InAppMessagePresentRequest) throws {
        var impressions = try storage.get(inAppMessage: request.inAppMessage)
        let impression = InAppMessageImpression(identifiers: request.user.identifiers, timestamp: request.requestedAt.timeIntervalSince1970)
        impressions.append(impression)

        if impressions.count > Self.STORE_MAX_SIZE {
            impressions.removeFirst(impressions.count - Self.STORE_MAX_SIZE)
        }

        try storage.set(inAppMessage: request.inAppMessage, impressions: impressions)
    }
}
