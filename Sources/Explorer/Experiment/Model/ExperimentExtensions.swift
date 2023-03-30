//
//  ExperimentExtensions.swift
//  Hackle
//
//  Created by yong on 2023/03/30.
//

import Foundation


class DecisionReasons {

    private static let notOverridableReasons = [
        "SDK_NOT_READY",
        "EXCEPTION",
        "INVALID_INPUT",
        "EXPERIMENT_NOT_FOUND",
        "IDENTIFIER_NOT_FOUND",
        "FEATURE_FLAG_NOT_FOUND",
        "FEATURE_FLAG_INACTIVE",
        "REMOTE_CONFIG_PARAMETER_NOT_FOUND",
        "TYPE_MISMATCH"
    ]


    static func isOverridable(reason: String) -> Bool {
        !notOverridableReasons.contains(reason)
    }
}
