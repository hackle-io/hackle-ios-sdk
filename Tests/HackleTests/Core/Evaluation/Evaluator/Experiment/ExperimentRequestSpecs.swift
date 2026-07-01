//
//  ExperimentRequestSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
@testable import Hackle


func experimentRequest(
    workspace: WorkspaceConfig = MockWorkspace(),
    user: HackleUser = HackleUser.builder().identifier(IdentifierType.id, "user").build(),
    experiment: ExperimentConfig = MockExperiment(),
    defaultVariation: String = "A"
) -> ExperimentLocalEvaluateRequest {
    ExperimentLocalEvaluateRequest(
        workspace: workspace,
        entity: experiment,
        user: user,
        record: true,
        defaultVariationKey: defaultVariation
    )
}