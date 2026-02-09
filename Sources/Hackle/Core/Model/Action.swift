import Foundation

protocol Action: Sendable {
    var type: ActionType { get }
    var variationId: Variation.Id? { get }
    var bucketId: Bucket.Id? { get }
}

enum ActionType: String, Codable {
    case variation = "VARIATION"
    case bucket = "BUCKET"
}


final class ActionEntity: Action, Sendable {
    let type: ActionType
    let variationId: Variation.Id?
    let bucketId: Bucket.Id?

    init(type: ActionType, variationId: Variation.Id?, bucketId: Bucket.Id?) {
        self.type = type
        self.variationId = variationId
        self.bucketId = bucketId
    }
}