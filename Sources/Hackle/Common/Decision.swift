import Foundation

@objc public final class Decision: NSObject, ParameterConfig {

    @objc public let experiment: HackleExperiment?
    @objc public let variation: String
    @objc public let reason: String
    @objc public let config: ParameterConfig
    @objc public let parameters: [String: Any]

    internal init(experiment: HackleExperiment?, variation: String, reason: String, config: ParameterConfig) {
        self.experiment = experiment
        self.variation = variation
        self.reason = reason
        self.config = config
        self.parameters = config.parameters
    }

    internal static func of(
        experiment: Experiment?,
        variation: String,
        reason: String,
        config: ParameterConfig = EmptyParameterConfig.instance
    ) -> Decision {
        Decision(experiment: experiment?.toPublic(), variation: variation, reason: reason, config: config)
    }

    public func getString(forKey: String, defaultValue: String) -> String {
        config.getString(forKey: forKey, defaultValue: defaultValue)
    }

    public func getInt(forKey: String, defaultValue: Int) -> Int {
        config.getInt(forKey: forKey, defaultValue: defaultValue)
    }

    public func getDouble(forKey: String, defaultValue: Double) -> Double {
        config.getDouble(forKey: forKey, defaultValue: defaultValue)
    }

    public func getBool(forKey: String, defaultValue: Bool) -> Bool {
        config.getBool(forKey: forKey, defaultValue: defaultValue)
    }
}

@objc public final class FeatureFlagDecision: NSObject, ParameterConfig {

    @objc public let featureFlag: HackleExperiment?
    @objc public let isOn: Bool
    @objc public let reason: String
    @objc public let config: ParameterConfig
    @objc public let parameters: [String: Any]

    init(featureFlag: HackleExperiment?, isOn: Bool, reason: String, config: ParameterConfig) {
        self.featureFlag = featureFlag
        self.isOn = isOn
        self.reason = reason
        self.config = config
        self.parameters = config.parameters
    }

    static func on(
        featureFlag: Experiment?,
        reason: String,
        config: ParameterConfig = EmptyParameterConfig.instance
    ) -> FeatureFlagDecision {
        FeatureFlagDecision(featureFlag: featureFlag?.toPublic(), isOn: true, reason: reason, config: config)
    }

    static func off(
        featureFlag: Experiment?,
        reason: String,
        config: ParameterConfig = EmptyParameterConfig.instance
    ) -> FeatureFlagDecision {
        FeatureFlagDecision(featureFlag: featureFlag?.toPublic(), isOn: false, reason: reason, config: config)
    }

    public func getString(forKey: String, defaultValue: String) -> String {
        config.getString(forKey: forKey, defaultValue: defaultValue)
    }

    public func getInt(forKey: String, defaultValue: Int) -> Int {
        config.getInt(forKey: forKey, defaultValue: defaultValue)
    }

    public func getDouble(forKey: String, defaultValue: Double) -> Double {
        config.getDouble(forKey: forKey, defaultValue: defaultValue)
    }

    public func getBool(forKey: String, defaultValue: Bool) -> Bool {
        config.getBool(forKey: forKey, defaultValue: defaultValue)
    }
}

final class RemoteConfigDecision {

    let value: HackleValue
    let reason: String

    init(value: HackleValue, reason: String) {
        self.value = value
        self.reason = reason
    }
}

final class InAppMessageDecision {

    let inAppMessage: InAppMessage?
    let message: InAppMessage.Message?
    let reason: String

    var isShow: Bool {
        inAppMessage != nil && message != nil
    }

    private init(inAppMessage: InAppMessage?, message: InAppMessage.Message?, reason: String) {
        self.inAppMessage = inAppMessage
        self.message = message
        self.reason = reason
    }

    static func of(inAppMessage: InAppMessage? = nil, message: InAppMessage.Message? = nil, reason: String) -> InAppMessageDecision {
        InAppMessageDecision(inAppMessage: inAppMessage, message: message, reason: reason)
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
    static let TRAFFIC_ALLOCATED_BY_TARGETING = "TRAFFIC_ALLOCATED_BY_TARGETING"
    static let NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT = "NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT"
    static let IDENTIFIER_NOT_FOUND = "IDENTIFIER_NOT_FOUND"
    static let VARIATION_DROPPED = "VARIATION_DROPPED"
    static let NOT_IN_EXPERIMENT_TARGET = "NOT_IN_EXPERIMENT_TARGET"

    static let FEATURE_FLAG_NOT_FOUND = "FEATURE_FLAG_NOT_FOUND"
    static let FEATURE_FLAG_INACTIVE = "FEATURE_FLAG_INACTIVE"
    static let INDIVIDUAL_TARGET_MATCH = "INDIVIDUAL_TARGET_MATCH"
    static let TARGET_RULE_MATCH = "TARGET_RULE_MATCH"
    static let DEFAULT_RULE = "DEFAULT_RULE"
    static let REMOTE_CONFIG_PARAMETER_NOT_FOUND = "REMOTE_CONFIG_PARAMETER_NOT_FOUND"
    static let TYPE_MISMATCH = "TYPE_MISMATCH"

    static let UNSUPPORTED_PLATFORM = "UNSUPPORTED_PLATFORM"

    static let IN_APP_MESSAGE_NOT_FOUND = "IN_APP_MESSAGE_NOT_FOUND"
    static let IN_APP_MESSAGE_DRAFT = "IN_APP_MESSAGE_DRAFT"
    static let IN_APP_MESSAGE_PAUSED = "IN_APP_MESSAGE_PAUSED"
    static let IN_APP_MESSAGE_HIDDEN = "IN_APP_MESSAGE_HIDDEN"
    static let IN_APP_MESSAGE_TARGET = "IN_APP_MESSAGE_TARGET"
    static let NOT_IN_IN_APP_MESSAGE_PERIOD = "NOT_IN_IN_APP_MESSAGE_PERIOD"
    static let NOT_IN_IN_APP_MESSAGE_TARGET = "NOT_IN_IN_APP_MESSAGE_TARGET"
}
