//
//  RemoteConfigRequestSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
@testable import Hackle

func remoteConfigRequest(
    workspace: Workspace = MockWorkspace(),
    user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
    parameter: RemoteConfigParameter = RemoteConfigParameter(id: 1, key: "key", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 1, rawValue: .string("parameter default"))),
    defaultValue: HackleValue = .string("default")
) -> RemoteConfigRequest {
    RemoteConfigRequest.of(workspace: workspace, user: user, parameter: parameter, defaultValue: defaultValue)
}