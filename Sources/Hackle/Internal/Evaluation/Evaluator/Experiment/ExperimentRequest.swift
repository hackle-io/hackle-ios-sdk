//
//  ExperimentRequest.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

class ExperimentRequest: EvaluatorRequest, Equatable, CustomStringConvertible {

    let key: EvaluatorKey
    let workspace: Workspace
    let user: HackleUser
    let experiment: Experiment
    let defaultVariationKey: String

    private init(workspace: Workspace, user: HackleUser, experiment: Experiment, defaultVariationKey: String) {
        self.key = EvaluatorKey(type: .experiment, id: experiment.id)
        self.workspace = workspace
        self.user = user
        self.experiment = experiment
        self.defaultVariationKey = defaultVariationKey
    }

    var description: String {
        "EvaluatorRequest(type=\(experiment.type.rawValue), key=\(experiment.key))"
    }

    static func ==(lhs: ExperimentRequest, rhs: ExperimentRequest) -> Bool {
        lhs.key == rhs.key
    }

    static func of(workspace: Workspace, user: HackleUser, experiment: Experiment, defaultVariationKey: String) -> ExperimentRequest {
        ExperimentRequest(workspace: workspace, user: user, experiment: experiment, defaultVariationKey: defaultVariationKey)
    }

    static func of(requestedBy: EvaluatorRequest, experiment: Experiment) -> ExperimentRequest {
        ExperimentRequest(workspace: requestedBy.workspace, user: requestedBy.user, experiment: experiment, defaultVariationKey: "A")
    }
}