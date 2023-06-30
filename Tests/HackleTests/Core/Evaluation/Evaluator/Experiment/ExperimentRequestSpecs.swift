//
//  ExperimentRequestSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
@testable import Hackle


func experimentRequest(
    workspace: Workspace = MockWorkspace(),
    user: HackleUser = HackleUser.builder().identifier(IdentifierType.id, "user").build(),
    experiment: Experiment = MockExperiment(),
    defaultVariation: String = "A"
) -> ExperimentRequest {
    ExperimentRequest.of(workspace: workspace, user: user, experiment: experiment, defaultVariationKey: defaultVariation)
}