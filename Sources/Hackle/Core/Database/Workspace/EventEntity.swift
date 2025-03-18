//
//  EventEntity.swift
//  Hackle
//
//  Created by yong on 2022/11/02.
//

import Foundation

class EventEntity {
    let id: Int64
    let type: UserEventType
    let status: EventEntityStatus
    let body: String

    init(id: Int64, type: UserEventType, status: EventEntityStatus, body: String) {
        self.id = id
        self.type = type
        self.status = status
        self.body = body
    }

    static let TABLE_NAME = "events"
    static let ID_COLUMN_NAME = "id"
    static let TYPE_COLUMN_NAME = "type"
    static let STATUS_COLUMN_NAME = "status"
    static let BODY_COLUMN_NAME = "body"

    static let CREATE_TABLE = "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (\(ID_COLUMN_NAME) INTEGER PRIMARY KEY AUTOINCREMENT, \(STATUS_COLUMN_NAME) INTEGER, \(TYPE_COLUMN_NAME) INTEGER, \(BODY_COLUMN_NAME) TEXT)"
    
    static let DROP_TABLE = "DROP TABLE IF EXISTS \(TABLE_NAME)"
}

enum EventEntityStatus: Int {
    case pending = 0
    case flushing = 1
}

extension UserEvent {
    func toBody() -> String? {
        switch self {
        case let exposure as UserEvents.Exposure:
            return exposure.toDto().toJson()
        case let track as UserEvents.Track:
            return track.toDto().toJson()
        case let remoteConfig as UserEvents.RemoteConfig:
            return remoteConfig.toDto().toJson()
        default:
            return nil
        }
    }
}
