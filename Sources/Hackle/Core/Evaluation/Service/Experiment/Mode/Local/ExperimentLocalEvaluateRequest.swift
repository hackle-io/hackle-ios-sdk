//
//  ExperimentLocalEvaluateRequest.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

final class ExperimentLocalEvaluateRequest: LocalEvaluateRequest, ExperimentEvaluateRequest, CustomStringConvertible {

    let workspace: WorkspaceConfig
    let experimentConfig: ExperimentConfig
    let user: HackleUser
    let record: Bool
    let defaultVariationKey: String

    var entity: ConfigEntity { experimentConfig }
    var experiment: Experiment { experimentConfig }

    init(workspace: WorkspaceConfig, entity: ExperimentConfig, user: HackleUser, record: Bool, defaultVariationKey: String) {
        self.workspace = workspace
        self.experimentConfig = entity
        self.user = user
        self.record = record
        self.defaultVariationKey = defaultVariationKey
    }

    var description: String {
        "ExperimentEvaluateRequest(type=\(experimentConfig.type.rawValue), key=\(experimentConfig.key))"
    }

    static func of(requestedBy: LocalEvaluateRequest, experiment: ExperimentConfig) -> ExperimentLocalEvaluateRequest {
        ExperimentLocalEvaluateRequest(
            workspace: requestedBy.workspace,
            entity: experiment,
            user: requestedBy.user,
            record: requestedBy.record,
            defaultVariationKey: "A"
        )
    }
}
