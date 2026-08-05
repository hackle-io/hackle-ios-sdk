//
//  ExperimentLocalEvaluateRequest.swift
//  Hackle
//

import Foundation

final class ExperimentLocalEvaluateRequest: LocalEvaluateRequest, ExperimentEvaluateRequest, CustomStringConvertible {

    let workspaceConfig: WorkspaceConfig
    let experimentConfig: ExperimentConfig
    let user: HackleUser
    let record: Bool

    var experiment: Experiment { experimentConfig }

    init(workspace: WorkspaceConfig, entity: ExperimentConfig, user: HackleUser, record: Bool) {
        self.workspaceConfig = workspace
        self.experimentConfig = entity
        self.user = user
        self.record = record
    }

    var description: String {
        "ExperimentEvaluateRequest(type=\(experimentConfig.type.rawValue), key=\(experimentConfig.key))"
    }

    static func of(requestedBy: LocalEvaluateRequest, experiment: ExperimentConfig) -> ExperimentLocalEvaluateRequest {
        ExperimentLocalEvaluateRequest(
            workspace: requestedBy.workspaceConfig,
            entity: experiment,
            user: requestedBy.user,
            record: requestedBy.record
        )
    }
}
