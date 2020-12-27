//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Variation {

    typealias Id = Int64
    typealias Key = String

    var id: Id { get }
    var key: Key { get }
    var isDropped: Bool { get }
}

class VariationEntity: Variation {

    let id: Id
    let key: Key
    let isDropped: Bool

    init(id: Id, key: Key, isDropped: Bool) {
        self.id = id
        self.key = key
        self.isDropped = isDropped
    }
}
