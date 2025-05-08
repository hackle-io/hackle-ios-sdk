//
//  ExperimentExtensions.swift
//  Hackle
//
//  Created by yong on 2023/03/30.
//

import Foundation


class DecisionReasons {

    private static let notOverridableReasons = [
        DecisionReason.SDK_NOT_READY,
        DecisionReason.EXCEPTION,
        DecisionReason.INVALID_INPUT,
        DecisionReason.EXPERIMENT_NOT_FOUND,
        DecisionReason.IDENTIFIER_NOT_FOUND,
        DecisionReason.FEATURE_FLAG_NOT_FOUND,
        DecisionReason.FEATURE_FLAG_INACTIVE,
        DecisionReason.REMOTE_CONFIG_PARAMETER_NOT_FOUND,
        DecisionReason.TYPE_MISMATCH,
        DecisionReason.IN_APP_MESSAGE_NOT_FOUND,
        DecisionReason.UNSUPPORTED_PLATFORM,
        DecisionReason.IN_APP_MESSAGE_DRAFT,
        DecisionReason.IN_APP_MESSAGE_PAUSED,
        DecisionReason.IN_APP_MESSAGE_HIDDEN,
        DecisionReason.IN_APP_MESSAGE_TARGET,
        DecisionReason.NOT_IN_IN_APP_MESSAGE_PERIOD,
        DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET,
        DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED,
        DecisionReason.EXPERIMENT_CONTROL_GROUP
    ]


    static func isOverridable(reason: String) -> Bool {
        !notOverridableReasons.contains(reason)
    }
}
