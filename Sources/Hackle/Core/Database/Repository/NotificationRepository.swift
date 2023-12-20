import Foundation

protocol NotificationRepository {
    func count() -> Int
    func save(entity: NotificationEntity)
    func getNotifications(workspaceId: Int, environmentId: Int, limit: Int?) -> [NotificationEntity]
    func delete(entities: [NotificationEntity])
}

class NotificationRepositoryImpl: NotificationRepository {
    private let sharedDatabase: SharedDatabase
    
    init(sharedDatabase: SharedDatabase) {
        self.sharedDatabase = sharedDatabase
    }
    
    func count() -> Int {
        let query = "SELECT COUNT(*) FROM \(NotificationEntity.TABLE_NAME)"
        do {
            return try sharedDatabase.execute { database -> Int in
                try database.queryForInt(sql: query)
            }
        } catch {
            Log.error("Failed to count notifications: \(error)")
            return 0
        }
    }
    
    func save(entity: NotificationEntity) {
        let query =
            "INSERT INTO \(NotificationEntity.TABLE_NAME) (" +
                "\(NotificationEntity.COLUMN_WORKSPACE_ID)," +
                "\(NotificationEntity.COLUMN_ENVIRONMENT_ID)," +
                "\(NotificationEntity.COLUMN_PUSH_MESSAGE_ID)," +
                "\(NotificationEntity.COLUMN_PUSH_MESSAGE_KEY)," +
                "\(NotificationEntity.COLUMN_PUSH_MESSAGE_EXECUTION_ID)," +
                "\(NotificationEntity.COLUMN_PUSH_MESSAGE_DELIVERY_ID)," +
                "\(NotificationEntity.COLUMN_CLICK_TIMESTAMP)" +
            ") VALUES (?, ?, ?, ?, ?, ?, ?)"
        do {
            try sharedDatabase.execute { database in
                try database.statement(sql: query)
                    .use { statement in
                        try statement.bindInt(index: 1, value: entity.workspaceId)
                        try statement.bindInt(index: 2, value: entity.environmentId)
                        try statement.bindInt(index: 3, value: entity.pushMessageId)
                        try statement.bindInt(index: 4, value: entity.pushMessageKey)
                        try statement.bindInt(index: 5, value: entity.pushMessageExecutionId)
                        try statement.bindInt(index: 6, value: entity.pushMessageDeliveryId)
                        try statement.bindDouble(index: 7, value: entity.clickTimestamp.timeIntervalSince1970)
                        try statement.execute()
                    }
            }
        } catch {
            Log.error("Failed to save notification: \(error)")
        }
    }
    
    func getNotifications(workspaceId: Int, environmentId: Int, limit: Int? = nil) -> [NotificationEntity] {
        var query =
            "SELECT * FROM \(NotificationEntity.TABLE_NAME) " +
                "WHERE \(NotificationEntity.COLUMN_WORKSPACE_ID) = \(workspaceId) AND " +
                    "\(NotificationEntity.COLUMN_ENVIRONMENT_ID) = \(environmentId)"
        if let limit = limit {
            query.append(" LIMIT \(limit)")
        }
        
        do {
            return try sharedDatabase.execute { database -> [NotificationEntity] in
                try database.query(sql: query)
                    .use { cursor in
                        var entities = [NotificationEntity]()
                        while cursor.moveToNext() {
                            let entity = NotificationEntity.from(cursor: cursor)
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
    
    func delete(entities: [NotificationEntity]) {
        let ids = entities.map { entity in String(entity.notificationId) }
            .joined(separator: ",")
        let query = 
            "DELETE FROM \(NotificationEntity.TABLE_NAME) " +
                "WHERE \(NotificationEntity.COLUMN_NOTIFICATION_ID) IN (\(ids))"
        
        do {
            try sharedDatabase.execute { database in
                try database.execute(sql: query)
            }
        } catch {
            Log.error("Failed to delete notifications: \(error)")
        }
    }
}
