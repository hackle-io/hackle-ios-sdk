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
                "WHERE \(NotificationHistoryEntity.COLUMN_WORKSPACE_ID) = \(workspaceId) AND " +
                    "\(NotificationHistoryEntity.COLUMN_ENVIRONMENT_ID) = \(environmentId)"
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
        let query =
            "INSERT INTO \(NotificationHistoryEntity.TABLE_NAME) (" +
                "\(NotificationHistoryEntity.COLUMN_WORKSPACE_ID)," +
                "\(NotificationHistoryEntity.COLUMN_ENVIRONMENT_ID)," +
                "\(NotificationHistoryEntity.COLUMN_PUSH_MESSAGE_ID)," +
                "\(NotificationHistoryEntity.COLUMN_PUSH_MESSAGE_KEY)," +
                "\(NotificationHistoryEntity.COLUMN_PUSH_MESSAGE_EXECUTION_ID)," +
                "\(NotificationHistoryEntity.COLUMN_PUSH_MESSAGE_DELIVERY_ID)," +
                "\(NotificationHistoryEntity.COLUMN_JOURNEY_ID)," +
                "\(NotificationHistoryEntity.COLUMN_JOURNEY_KEY)," +
                "\(NotificationHistoryEntity.COLUMN_JOURNEY_NODE_ID)," +
                "\(NotificationHistoryEntity.COLUMN_CAMPAIGN_TYPE)," +
                "\(NotificationHistoryEntity.COLUMN_TIMESTAMP)," +
                "\(NotificationHistoryEntity.COLUMN_DEBUG)" +
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        do {
            try sharedDatabase.execute { database in
                try database.statement(sql: query)
                    .use { statement in
                        try statement.bindInt(index: 1, value: data.workspaceId)
                        try statement.bindInt(index: 2, value: data.environmentId)
                        try statement.bindInt(index: 3, value: data.pushMessageId)
                        try statement.bindInt(index: 4, value: data.pushMessageKey)
                        try statement.bindInt(index: 5, value: data.pushMessageExecutionId)
                        try statement.bindInt(index: 6, value: data.pushMessageDeliveryId)
                        try statement.bindInt(index: 7, value: data.journeyId)
                        try statement.bindInt(index: 8, value: data.journeyKey)
                        try statement.bindInt(index: 9, value: data.journeyNodeId)
                        try statement.bindString(index: 10, value: data.campaignType)
                        try statement.bindDouble(index: 11, value: timestamp.timeIntervalSince1970)
                        try statement.bindBool(index: 12, value: data.debug)
                        try statement.execute()
                    }
            }
        } catch {
            Log.error("Failed to save notification: \(error)")
        }
    }
    
    func getEntities(workspaceId: Int64, environmentId: Int64, limit: Int? = nil) -> [NotificationHistoryEntity] {
        var query =
            "SELECT * FROM \(NotificationHistoryEntity.TABLE_NAME) " +
                "WHERE \(NotificationHistoryEntity.COLUMN_WORKSPACE_ID) = \(workspaceId) AND " +
                    "\(NotificationHistoryEntity.COLUMN_ENVIRONMENT_ID) = \(environmentId)"
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
                "WHERE \(NotificationHistoryEntity.COLUMN_HISTORY_ID) IN (\(ids))"
        
        do {
            try sharedDatabase.execute { database in
                try database.execute(sql: query)
            }
        } catch {
            Log.error("Failed to delete notifications: \(error)")
        }
    }
}
