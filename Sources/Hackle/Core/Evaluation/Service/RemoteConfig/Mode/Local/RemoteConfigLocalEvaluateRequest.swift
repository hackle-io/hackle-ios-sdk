//
//  RemoteConfigLocalEvaluateRequest.swift
//  Hackle
//

import Foundation

final class RemoteConfigLocalEvaluateRequest: LocalEvaluateRequest, RemoteConfigEvaluateRequest, Equatable, CustomStringConvertible {

    let workspace: Workspace
    let parameter: RemoteConfigParameter
    let user: HackleUser
    let record: Bool
    let defaultValue: HackleValue

    var entity: Entity { parameter }

    private init(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser, record: Bool, defaultValue: HackleValue) {
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
        workspace: Workspace,
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
