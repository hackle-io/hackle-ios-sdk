//
//  RemoteConfigRequest.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation


class RemoteConfigRequest: EvaluatorRequest, Equatable, CustomStringConvertible {
    let key: EvaluatorKey
    let workspace: Workspace
    let user: HackleUser
    let parameter: RemoteConfigParameter
    let defaultValue: HackleValue

    private init(workspace: Workspace, user: HackleUser, parameter: RemoteConfigParameter, defaultValue: HackleValue) {
        self.key = EvaluatorKey(type: .remoteConfig, id: parameter.id)
        self.workspace = workspace
        self.user = user
        self.parameter = parameter
        self.defaultValue = defaultValue
    }

    var description: String {
        "EvaluatorRequest(type=\(EvaluatorType.remoteConfig.rawValue), key=\(parameter.key))"
    }

    static func ==(lhs: RemoteConfigRequest, rhs: RemoteConfigRequest) -> Bool {
        lhs.key == rhs.key
    }

    static func of(workspace: Workspace, user: HackleUser, parameter: RemoteConfigParameter, defaultValue: HackleValue) -> RemoteConfigRequest {
        RemoteConfigRequest(workspace: workspace, user: user, parameter: parameter, defaultValue: defaultValue)
    }
}
