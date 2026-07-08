//
//  RemoteConfigLocalEvaluateRequest.swift
//  Hackle
//

import Foundation

final class RemoteConfigLocalEvaluateRequest: LocalEvaluateRequest, RemoteConfigEvaluateRequest, Equatable, CustomStringConvertible {

    let workspace: Workspace
    let parameterConfig: RemoteConfigParameterConfig
    let user: HackleUser
    let record: Bool
    let requiredType: HackleValueType

    var parameter: RemoteConfigParameter { parameterConfig }
    var entity: Entity { parameterConfig }

    private init(workspace: Workspace, parameter: RemoteConfigParameterConfig, user: HackleUser, record: Bool, requiredType: HackleValueType) {
        self.workspace = workspace
        self.parameterConfig = parameter
        self.user = user
        self.record = record
        self.requiredType = requiredType
    }

    var description: String {
        "RemoteConfigEvaluateRequest(key=\(parameterConfig.key))"
    }

    static func ==(lhs: RemoteConfigLocalEvaluateRequest, rhs: RemoteConfigLocalEvaluateRequest) -> Bool {
        lhs.parameterConfig.entityKey == rhs.parameterConfig.entityKey
    }

    static func of(
        workspace: Workspace,
        parameter: RemoteConfigParameterConfig,
        user: HackleUser,
        requiredType: HackleValueType,
        record: Bool = true
    ) -> RemoteConfigLocalEvaluateRequest {
        RemoteConfigLocalEvaluateRequest(
            workspace: workspace,
            parameter: parameter,
            user: user,
            record: record,
            requiredType: requiredType
        )
    }
}
