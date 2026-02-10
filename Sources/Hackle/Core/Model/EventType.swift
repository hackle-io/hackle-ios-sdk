//
// Created by yong on 2020/12/11.
//

import Foundation

protocol EventType: Sendable {

    typealias Id = Int64
    typealias Key = String

    var id: Id { get }
    var key: Key { get }
}

final class EventTypeEntity: EventType {
    let id: Id
    let key: Key

    init(id: Id, key: Key) {
        self.id = id
        self.key = key
    }
}

final class UndefinedEventType: EventType {
    let id: Id = 0
    let key: Key

    init(key: Key) {
        self.key = key
    }
}