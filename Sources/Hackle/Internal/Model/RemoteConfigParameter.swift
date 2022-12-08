//
//  RemoteConfigParameter.swift
//  Hackle
//
//  Created by yong on 2022/11/17.
//

import Foundation


class RemoteConfigParameter {
    typealias Id = Int64
    typealias Key = String

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

    class Value {
        let id: Int64
        let rawValue: HackleValue

        init(id: Int64, rawValue: HackleValue) {
            self.id = id
            self.rawValue = rawValue
        }
    }

    class TargetRule {
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
