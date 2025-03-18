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

extension EventEntity {
    static let TABLE_NAME = "events"
    
    enum Column: String {
        case id = "id"
        case type = "type"
        case status = "status"
        case body = "body"
        
        var index: Int32 {
            switch self {
            case .id: return 0
            case .type: return 1
            case .status: return 2
            case .body: return 3
            }
        }
    }

    static let CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (" +
            "\(Column.id.rawValue) INTEGER PRIMARY KEY AUTOINCREMENT," +
            "\(Column.status.rawValue) INTEGER," +
            "\(Column.type.rawValue) INTEGER," +
            "\(Column.body.rawValue) TEXT" +
        ")"
    
    static let DROP_TABLE = 
        "DROP TABLE IF EXISTS \(TABLE_NAME)"
    
    static let INSERT_TABLE =
        "INSERT INTO \(TABLE_NAME) (" +
            "\(Column.type.rawValue)," +
            "\(Column.status.rawValue)," +
            "\(Column.body.rawValue)" +
        ") VALUES (?, ?, ?)"
    
    static func bind(statement: SQLiteStatement, type: UserEventType, body: String) throws {
        try statement.bindInt(index: Column.type.index, value: Int32(type.rawValue))
        try statement.bindInt(index: Column.status.index, value: Int32(EventEntityStatus.pending.rawValue))
        try statement.bindString(index: Column.body.index, value: body)
        try statement.execute()
    }
}
