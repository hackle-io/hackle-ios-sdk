//
// Created by yong on 2020/12/11.
//

import Foundation

protocol EventType {

    typealias Id = Int64
    typealias Key = String

    var id: Id { get }
    var key: Key { get }
}

class EventTypeEntity: EventType {
    let id: Id
    let key: Key

    init(id: Id, key: Key) {
        self.id = id
        self.key = key
    }
}

class UndefinedEventType: EventType {
    let id: Id = 0
    let key: Key

    init(key: Key) {
        self.key = key
    }
}