import Foundation

protocol NotificationRepository {
    func count(workspaceId: Int64, environmentId: Int64) -> Int
    func save(data: NotificationData, timestamp: Date)
    func getEntities(workspaceId: Int64, environmentId: Int64, limit: Int?) -> [NotificationHistoryEntity]
    func delete(entities: [NotificationHistoryEntity])
}

class DefaultNotificationRepository: NotificationRepository {
    private let sharedDatabase: SharedDatabase
    
    init(sharedDatabase: SharedDatabase) {
        self.sharedDatabase = sharedDatabase
    }
    
    func count(workspaceId: Int64, environmentId: Int64) -> Int {
        let query = 
            "SELECT COUNT(*) FROM \(NotificationHistoryEntity.TABLE_NAME) " +
                "WHERE \(NotificationHistoryEntity.WORKSPACE_ID_COLUMN_NAME) = \(workspaceId) AND " +
                    "\(NotificationHistoryEntity.ENVIRONMENT_ID_COLUMN_NAME) = \(environmentId)"
        do {
            return try sharedDatabase.execute { database -> Int in
                try database.queryForInt(sql: query)
            }
        } catch {
            Log.error("Failed to count notifications: \(error)")
            return 0
        }
    }
    
    func save(data: NotificationData, timestamp: Date) {
        do {
            try sharedDatabase.execute { database in
                try database.statement(sql: NotificationHistoryEntity.INSERT_TABLE)
                    .use { statement in
                        try NotificationHistoryEntity.bind(statement: statement, data: data, timestamp: timestamp)
                    }
            }
        } catch {
            Log.error("Failed to save notification: \(error)")
        }
    }
    
    func getEntities(workspaceId: Int64, environmentId: Int64, limit: Int? = nil) -> [NotificationHistoryEntity] {
        var query =
            "SELECT * FROM \(NotificationHistoryEntity.TABLE_NAME) " +
                "WHERE \(NotificationHistoryEntity.WORKSPACE_ID_COLUMN_NAME) = \(workspaceId) AND " +
                    "\(NotificationHistoryEntity.ENVIRONMENT_ID_COLUMN_NAME) = \(environmentId)"
        if let limit = limit {
            query.append(" LIMIT \(limit)")
        }
        
        do {
            return try sharedDatabase.execute { database -> [NotificationHistoryEntity] in
                try database.query(sql: query)
                    .use { cursor in
                        var entities = [NotificationHistoryEntity]()
                        while cursor.moveToNext() {
                            let entity = NotificationHistoryEntity.from(cursor: cursor)
                            entities.append(entity)
                        }
                        return entities
                    }
            }
        } catch {
            Log.error("Failed to get notifications: \(error)")
            return []
        }
    }
    
    func delete(entities: [NotificationHistoryEntity]) {
        let ids = entities.map { entity in String(entity.historyId) }
            .joined(separator: ",")
        let query = 
            "DELETE FROM \(NotificationHistoryEntity.TABLE_NAME) " +
                "WHERE \(NotificationHistoryEntity.HISTORY_ID_COLUMN_NAME) IN (\(ids))"
        
        do {
            try sharedDatabase.execute { database in
                try database.execute(sql: query)
            }
        } catch {
            Log.error("Failed to delete notifications: \(error)")
        }
    }
}
