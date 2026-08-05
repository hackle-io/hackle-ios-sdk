//
//  RemoteConfigRequestSpecs.swift
//  HackleTests
//

import Foundation
@testable import Hackle

func remoteConfigRequest(
    workspace: WorkspaceConfig = MockWorkspace(),
    user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
    parameter: RemoteConfigParameterConfig = RemoteConfigParameterEntity(id: 1, key: "key", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 1, rawValue: .string("parameter default"))),
    defaultValue: HackleValue = .string("default")
) -> RemoteConfigLocalEvaluateRequest {
    RemoteConfigLocalEvaluateRequest.of(workspace: workspace, entity: parameter, user: user, requiredType: defaultValue.type)
}