//
//  RemoteConfigLocalEvaluateRequest.swift
//  Hackle
//

import Foundation

final class RemoteConfigLocalEvaluateRequest: LocalEvaluateRequest, RemoteConfigEvaluateRequest, Equatable, CustomStringConvertible {

    let workspaceConfig: WorkspaceConfig
    let parameterConfig: RemoteConfigParameterConfig
    let user: HackleUser
    let record: Bool
    let requiredType: HackleValueType

    var parameter: RemoteConfigParameter { parameterConfig }

    private init(workspace: WorkspaceConfig, parameter: RemoteConfigParameterConfig, user: HackleUser, record: Bool, requiredType: HackleValueType) {
        self.workspaceConfig = workspace
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
        workspace: WorkspaceConfig,
        entity: RemoteConfigParameterConfig,
        user: HackleUser,
        requiredType: HackleValueType,
        record: Bool = true
    ) -> RemoteConfigLocalEvaluateRequest {
        RemoteConfigLocalEvaluateRequest(
            workspace: workspace,
            parameter: entity,
            user: user,
            record: record,
            requiredType: requiredType
        )
    }
}
