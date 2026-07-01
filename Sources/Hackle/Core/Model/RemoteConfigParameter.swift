//
//  RemoteConfigParameter.swift
//  Hackle
//

import Foundation


final class RemoteConfigParameter: RemoteConfigParameterConfig, Sendable {
    typealias Id = Int64
    typealias Key = String

    var serviceType: ServiceType {
        .remoteConfig
    }

    let id: Id
    let key: Key
    let type: HackleValueType
    let identifierType: String
    let targetRules: [TargetRule]
    let defaultValue: Value

    init(id: Id, key: Key, type: HackleValueType, identifierType: String, targetRules: [TargetRule], defaultValue: Value) {
        self.id = id
        self.key = key
        self.type = type
        self.identifierType = identifierType
        self.targetRules = targetRules
        self.defaultValue = defaultValue
    }

    final class Value: Sendable {
        let id: Int64
        let rawValue: HackleValue

        init(id: Int64, rawValue: HackleValue) {
            self.id = id
            self.rawValue = rawValue
        }
    }

    final class TargetRule: Sendable {
        let key: String
        let name: String
        let target: Target
        let bucketId: Bucket.Id
        let value: Value

        init(key: String, name: String, target: Target, bucketId: Bucket.Id, value: Value) {
            self.key = key
            self.name = name
            self.target = target
            self.bucketId = bucketId
            self.value = value
        }
    }
}
