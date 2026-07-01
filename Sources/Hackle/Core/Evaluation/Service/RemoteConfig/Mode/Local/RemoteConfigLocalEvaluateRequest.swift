//
//  RemoteConfigLocalEvaluateRequest.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

final class RemoteConfigLocalEvaluateRequest: LocalEvaluateRequest, RemoteConfigEvaluateRequest, Equatable, CustomStringConvertible {

    let workspace: WorkspaceConfig
    let parameter: RemoteConfigParameter
    let user: HackleUser
    let record: Bool
    let defaultValue: HackleValue

    var entity: ConfigEntity { parameter }

    private init(workspace: WorkspaceConfig, parameter: RemoteConfigParameter, user: HackleUser, record: Bool, defaultValue: HackleValue) {
        self.workspace = workspace
        self.parameter = parameter
        self.user = user
        self.record = record
        self.defaultValue = defaultValue
    }

    var description: String {
        "RemoteConfigEvaluateRequest(key=\(parameter.key))"
    }

    static func ==(lhs: RemoteConfigLocalEvaluateRequest, rhs: RemoteConfigLocalEvaluateRequest) -> Bool {
        lhs.parameter.entityKey == rhs.parameter.entityKey
    }

    static func of(
        workspace: WorkspaceConfig,
        parameter: RemoteConfigParameter,
        user: HackleUser,
        defaultValue: HackleValue,
        record: Bool = true
    ) -> RemoteConfigLocalEvaluateRequest {
        RemoteConfigLocalEvaluateRequest(
            workspace: workspace,
            parameter: parameter,
            user: user,
            record: record,
            defaultValue: defaultValue
        )
    }
}
