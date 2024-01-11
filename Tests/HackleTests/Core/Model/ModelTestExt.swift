//
//  ModelTestExt.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
@testable import Hackle


extension WorkspaceEntity {

    static func create(
        id: Int64 = 0,
        environmentId: Int64 = 0,
        experiments: [Experiment] = [],
        featureFlags: [Experiment] = [],
        buckets: [Bucket] = [],
        eventTypes: [EventType] = [],
        segments: [Segment] = [],
        containers: [Container] = [],
        parameterConfigurations: [ParameterConfiguration] = [],
        remoteConfigParameters: [RemoteConfigParameter] = [],
        inAppMessages: [InAppMessage] = []
    ) -> WorkspaceEntity {
        WorkspaceEntity(
            id: id,
            environmentId: environmentId,
            experiments: experiments,
            featureFlags: featureFlags,
            buckets: buckets,
            eventTypes: eventTypes,
            segments: segments,
            containers: containers,
            parameterConfigurations: parameterConfigurations,
            remoteConfigParameters: remoteConfigParameters,
            inAppMessages: inAppMessages
        )
    }
}

extension Target {

    static func create(_ conditions: Condition...) -> Target {
        Target(conditions: conditions)
    }

    static func condition(
        key: Key = key(),
        match: Match = match()
    ) -> Condition {
        Condition(key: key, match: match)
    }

    static func key(
        type: KeyType = .userProperty,
        name: String = "name"
    ) -> Key {
        Key(type: type, name: name)
    }

    static func match(
        type: MatchType = .match,
        op: Match.Operator = ._in,
        valueType: HackleValueType = .string,
        values: [HackleValue] = [.string("hackle")]
    ) -> Match {
        Match(type: type, matchOperator: op, valueType: valueType, values: values)
    }
}
