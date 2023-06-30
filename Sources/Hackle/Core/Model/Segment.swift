//
//  Segment.swift
//  Hackle
//
//  Created by yong on 2022/01/28.
//

import Foundation

protocol Segment {

    typealias Id = Int64
    typealias Key = String

    var id: Id { get }
    var key: Key { get }
    var type: SegmentType { get }
    var targets: [Target] { get }
}

enum SegmentType: String, Codable {
    case userId = "USER_ID"
    case userProperty = "USER_PROPERTY"
}

class SegmentEntity: Segment {

    let id: Id
    let key: Key
    let type: SegmentType
    let targets: [Target]

    init(id: Id, key: Key, type: SegmentType, targets: [Target]) {
        self.id = id
        self.key = key
        self.type = type
        self.targets = targets
    }
}
