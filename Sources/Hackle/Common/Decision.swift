import Foundation

@objc public final class Decision: NSObject {

    @objc public let variation: String
    @objc public let reason: String

    internal init(variation: String, reason: String) {
        self.variation = variation
        self.reason = reason
    }

    internal static func of(variation: String, reason: String) -> Decision {
        Decision(variation: variation, reason: reason)
    }
}

@objc public final class FeatureFlagDecision: NSObject {

    @objc public let isOn: Bool
    @objc public let reason: String

    init(isOn: Bool, reason: String) {
        self.isOn = isOn
        self.reason = reason
    }

    static func on(reason: String) -> FeatureFlagDecision {
        FeatureFlagDecision(isOn: true, reason: reason)
    }

    static func off(reason: String) -> FeatureFlagDecision {
        FeatureFlagDecision(isOn: false, reason: reason)
    }
}


class DecisionReason {

    static let SDK_NOT_READY = "SDK_NOT_READY"
    static let EXCEPTION = "EXCEPTION"
    static let INVALID_INPUT = "INVALID_INPUT"

    static let EXPERIMENT_NOT_FOUND = "EXPERIMENT_NOT_FOUND"
    static let EXPERIMENT_DRAFT = "EXPERIMENT_DRAFT"
    static let EXPERIMENT_PAUSED = "EXPERIMENT_PAUSED"
    static let EXPERIMENT_COMPLETED = "EXPERIMENT_COMPLETED"
    static let OVERRIDDEN = "OVERRIDDEN"
    static let TRAFFIC_NOT_ALLOCATED = "TRAFFIC_NOT_ALLOCATED"
    static let TRAFFIC_ALLOCATED = "TRAFFIC_ALLOCATED"
    static let NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT = "NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT"
    static let IDENTIFIER_NOT_FOUND = "IDENTIFIER_NOT_FOUND"
    static let VARIATION_DROPPED = "VARIATION_DROPPED"
    static let NOT_IN_EXPERIMENT_TARGET = "NOT_IN_EXPERIMENT_TARGET"

    static let FEATURE_FLAG_NOT_FOUND = "FEATURE_FLAG_NOT_FOUND"
    static let FEATURE_FLAG_INACTIVE = "FEATURE_FLAG_INACTIVE"
    static let INDIVIDUAL_TARGET_MATCH = "INDIVIDUAL_TARGET_MATCH"
    static let TARGET_RULE_MATCH = "TARGET_RULE_MATCH"
    static let DEFAULT_RULE = "DEFAULT_RULE"
}
