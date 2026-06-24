import Foundation

enum InAppMessageDetail {
    case target([TargetGroupDetail])
    case frequency(FrequencyDetail)
    case hidden(HiddenDetail)
}

struct TargetGroupDetail {
    let index: Int
    let conditions: [ConditionDetail]
}

struct ConditionDetail {
    let keyType: String      // USER_PROPERTY / HACKLE_PROPERTY / SEGMENT ...
    let keyName: String
    let requirement: String  // "GTE [20]", "IN [VIP, GOLD]"
    let userValue: String?
    let isMatched: Bool?
    let matchType: Target.MatchType
    let isUserProperty: Bool
}

struct FrequencyDetail {
    let caps: [CapStatus]
    let impressions: [ImpressionDetail]
}

struct CapStatus {
    let label: String
    let threshold: Int64
    let currentCount: Int
    let isExceeded: Bool
}

struct ImpressionDetail {
    let identifiers: String
    let timestamp: String
}

struct HiddenDetail {
    let expireAt: Date?
}
