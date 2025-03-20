//
//  EventRepository.swift
//  Hackle
//
//  Created by yong on 2022/11/02.
//

import Foundation

protocol EventRepository {

    func count() -> Int

    func countBy(status: EventEntityStatus) -> Int

    func save(event: UserEvent)

    func getEventToFlush(limit: Int) -> [EventEntity]

    func findAllBy(status: EventEntityStatus) -> [EventEntity]

    func update(events: [EventEntity], status: EventEntityStatus)

    func delete(events: [EventEntity])

    func deleteOldEvents(count: Int)
}

class SQLiteEventRepository: EventRepository {

    private let database: WorkspaceDatabase

    init(database: WorkspaceDatabase) {
        self.database = database
    }

    func count() -> Int {
        let sql = "SELECT COUNT(*) FROM \(EventEntity.TABLE_NAME)"
        do {
            return try database.execute { database -> Int in
                try database.queryForInt(sql: sql)
            }
        } catch {
            Log.error("Failed to count events: \(error)")
            return 0
        }
    }

    func countBy(status: EventEntityStatus) -> Int {
        let sql = "SELECT COUNT(*) FROM \(EventEntity.TABLE_NAME) WHERE \(EventEntity.STATUS_COLUMN_NAME) = \(status.rawValue)"
        do {
            return try database.execute { database -> Int in
                try database.queryForInt(sql: sql)
            }
        } catch {
            Log.error("Failed to count events: \(error)")
            return 0
        }
    }

    func save(event: UserEvent) {
        guard let body = event.toBody() else {
            return
        }
        do {
            let query =
                "INSERT INTO \(EventEntity.TABLE_NAME) (" +
                    "\(EventEntity.TYPE_COLUMN_NAME)," +
                    "\(EventEntity.STATUS_COLUMN_NAME)," +
                    "\(EventEntity.BODY_COLUMN_NAME)" +
                ") VALUES (?, ?, ?)"
            
            try database.execute { database in
                try database.statement(sql: query).use { statement in
                    try statement.bindInt(index: 1, value: Int32(event.type.rawValue))
                    try statement.bindInt(index: 2, value: Int32(EventEntityStatus.pending.rawValue))
                    try statement.bindString(index: 3, value: body)
                    try statement.execute()
                }
            }
        } catch {
            Log.error("Failed to save event: \(error)")
        }
    }

    func getEventToFlush(limit: Int) -> [EventEntity] {
        do {
            return try database.execute { database -> [EventEntity] in
                try getEventToFlush(database: database, limit: limit)
            }
        } catch let error {
            Log.error("Failed to get events: \(error)")
            return []
        }
    }

    private func getEventToFlush(database: SQLiteDatabase, limit: Int) throws -> [EventEntity] {
        let events = try getEvents(database: database, status: .pending, limit: limit)
        if !events.isEmpty {
            try update(database: database, events: events, status: .flushing)
        }
        return events
    }

    private func getEvents(database: SQLiteDatabase, status: EventEntityStatus, limit: Int? = nil) throws -> [EventEntity] {
        let sql: String
        if let limit = limit {
            sql = "SELECT \(EventEntity.ID_COLUMN_NAME), \(EventEntity.TYPE_COLUMN_NAME), \(EventEntity.STATUS_COLUMN_NAME), \(EventEntity.BODY_COLUMN_NAME) FROM \(EventEntity.TABLE_NAME) WHERE \(EventEntity.STATUS_COLUMN_NAME) = \(status.rawValue) ORDER BY \(EventEntity.ID_COLUMN_NAME) ASC LIMIT \(limit)"
        } else {
            sql = "SELECT \(EventEntity.ID_COLUMN_NAME), \(EventEntity.TYPE_COLUMN_NAME), \(EventEntity.STATUS_COLUMN_NAME), \(EventEntity.BODY_COLUMN_NAME) FROM \(EventEntity.TABLE_NAME) WHERE \(EventEntity.STATUS_COLUMN_NAME) = \(status.rawValue)"
        }

        return try database.query(sql: sql).use { cursor in
            var events = [EventEntity]()
            while cursor.moveToNext() {
                let event = EventEntity(
                    id: cursor.getInt64(0),
                    type: UserEventType(rawValue: cursor.getInt(1))!,
                    status: EventEntityStatus(rawValue: cursor.getInt(2))!,
                    body: cursor.getString(3)
                )
                events.append(event)
            }
            return events
        }
    }

    private func update(database: SQLiteDatabase, events: [EventEntity], status: EventEntityStatus) throws {
        let ids = events.map { it in
                String(it.id)
            }
            .joined(separator: ",")
        let sql = "UPDATE \(EventEntity.TABLE_NAME) SET \(EventEntity.STATUS_COLUMN_NAME) = \(status.rawValue) WHERE \(EventEntity.ID_COLUMN_NAME) IN (\(ids))"
        try database.execute(sql: sql)
    }

    func findAllBy(status: EventEntityStatus) -> [EventEntity] {
        do {
            return try database.execute { database -> [EventEntity] in
                try getEvents(database: database, status: status)
            }
        } catch {
            Log.error("Failed to get events: \(error)")
            return []
        }
    }

    func update(events: [EventEntity], status: EventEntityStatus) {
        do {
            try database.execute { database in
                try update(database: database, events: events, status: status)
            }
        } catch {
            Log.error("Failed to update events: \(error)")
        }
    }

    func delete(events: [EventEntity]) {
        let ids = events.map { it in
                String(it.id)
            }
            .joined(separator: ",")

        let sql = "DELETE FROM \(EventEntity.TABLE_NAME) WHERE \(EventEntity.ID_COLUMN_NAME) IN (\(ids))"

        do {
            try database.execute { database in
                try database.execute(sql: sql)
            }
        } catch {
            Log.error("Failed to delete events: \(error)")
        }
    }

    func deleteOldEvents(count: Int) {
        do {
            try database.execute { database in
                let id = try database.queryForInt(sql: "SELECT \(EventEntity.ID_COLUMN_NAME) FROM \(EventEntity.TABLE_NAME) LIMIT 1 OFFSET \(count - 1)")
                try database.execute(sql: "DELETE FROM \(EventEntity.TABLE_NAME) WHERE \(EventEntity.ID_COLUMN_NAME) <= \(id)")
            }
        } catch {
            Log.error("Failed to delete events: \(error)")
        }
    }
}
