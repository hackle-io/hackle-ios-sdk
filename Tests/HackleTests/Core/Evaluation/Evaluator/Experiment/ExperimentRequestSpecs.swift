//
//  ExperimentRequestSpecs.swift
//  HackleTests
//

import Foundation
@testable import Hackle


func experimentRequest(
    workspace: WorkspaceConfig = MockWorkspace(),
    user: HackleUser = HackleUser.builder().identifier(IdentifierType.id, "user").build(),
    experiment: ExperimentConfig = MockExperiment()
) -> ExperimentLocalEvaluateRequest {
    ExperimentLocalEvaluateRequest(
        workspace: workspace,
        entity: experiment,
        user: user,
        record: true
    )
}