import Foundation

class NotificationHistoryEntity {
    let historyId: Int64
    
    let workspaceId: Int64
    let environmentId: Int64
    
    let pushMessageId: Int64?
    let pushMessageKey: Int64?
    let pushMessageExecutionId: Int64?
    let pushMessageDeliveryId: Int64?
    
    let journeyId: Int64?
    let journeyKey: Int64?
    let journeyNodeId: Int64?
    let campaignType: String?
    
    let timestamp: Date
    let debug: Bool
    
    init(
        historyId: Int64,
        workspaceId: Int64,
        environmentId: Int64,
        pushMessageId: Int64?,
        pushMessageKey: Int64?,
        pushMessageExecutionId: Int64?,
        pushMessageDeliveryId: Int64?,
        timestamp: Date,
        debug: Bool,
        journeyId: Int64?,
        journeyKey: Int64?,
        journeyNodeId: Int64?,
        campaignType: String?
    ) {
        self.historyId = historyId
        self.workspaceId = workspaceId
        self.environmentId = environmentId
        self.pushMessageId = pushMessageId
        self.pushMessageKey = pushMessageKey
        self.pushMessageExecutionId = pushMessageExecutionId
        self.pushMessageDeliveryId = pushMessageDeliveryId
        self.timestamp = timestamp
        self.debug = debug
        self.journeyId = journeyId
        self.journeyKey = journeyKey
        self.journeyNodeId = journeyNodeId
        self.campaignType = campaignType
    }
}

extension NotificationHistoryEntity {
    static let TABLE_NAME = "notification_histories"
    
    static let HISTORY_ID_COLUMN_NAME = "history_id"
    static let WORKSPACE_ID_COLUMN_NAME = "workspace_id"
    static let ENVIRONMENT_ID_COLUMN_NAME = "environment_id"
    static let PUSH_MESSAGE_ID_COLUMN_NAME = "push_message_id"
    static let PUSH_MESSAGE_KEY_COLUMN_NAME = "push_message_key"
    static let PUSH_MESSAGE_EXECUTION_ID_COLUMN_NAME = "push_message_execution_id"
    static let PUSH_MESSAGE_DELIVERY_ID_COLUMN_NAME = "push_message_delivery_id"
    static let TIMESTAMP_COLUMN_NAME = "timestamp"
    static let DEBUG_COLUMN_NAME = "debug"
    static let JOURNEY_ID_COLUMN_NAME = "journey_id"
    static let JOURNEY_KEY_COLUMN_NAME = "journey_key"
    static let JOURNEY_NODE_ID_COLUMN_NAME = "journey_node_id"
    static let CAMPAIGN_TYPE_COLUMN_NAME = "campaign_type"
    
    static let DDL_LIST = [
        DatabaseDDL(
            version: 1,
            statements: [
                "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (" +
                    "\(HISTORY_ID_COLUMN_NAME) INTEGER PRIMARY KEY AUTOINCREMENT," +
                    "\(WORKSPACE_ID_COLUMN_NAME) INTEGER NOT NULL," +
                    "\(ENVIRONMENT_ID_COLUMN_NAME) INTEGER NOT NULL," +
                    "\(PUSH_MESSAGE_ID_COLUMN_NAME) INTEGER," +
                    "\(PUSH_MESSAGE_KEY_COLUMN_NAME) INTEGER," +
                    "\(PUSH_MESSAGE_EXECUTION_ID_COLUMN_NAME) INTEGER," +
                    "\(PUSH_MESSAGE_DELIVERY_ID_COLUMN_NAME) INTEGER," +
                    "\(TIMESTAMP_COLUMN_NAME) INTEGER," +
                    "\(DEBUG_COLUMN_NAME) INTEGER" +
                ")"
            ]
        ),
        DatabaseDDL(
            version: 2,
            statements: [
                "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(JOURNEY_ID_COLUMN_NAME) INTEGER",
                "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(JOURNEY_KEY_COLUMN_NAME) INTEGER",
                "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(JOURNEY_NODE_ID_COLUMN_NAME) INTEGER",
                "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(CAMPAIGN_TYPE_COLUMN_NAME) TEXT"
            ]
         )
    ]

    static let DROP_TABLE =
        "DROP TABLE IF EXISTS \(TABLE_NAME)"
    
    static func from(cursor: SQLiteCursor) -> NotificationHistoryEntity {
        return NotificationHistoryEntity(
            historyId: cursor.getInt64(0),
            workspaceId: cursor.getInt64(1),
            environmentId: cursor.getInt64(2),
            pushMessageId: cursor.getInt64(3),
            pushMessageKey: cursor.getInt64(4),
            pushMessageExecutionId: cursor.getInt64(5),
            pushMessageDeliveryId: cursor.getInt64(6),
            timestamp: Date(timeIntervalSince1970: cursor.getDouble(7)),
            debug: cursor.getBool(8),
            journeyId: cursor.getInt64(9),
            journeyKey: cursor.getInt64(10),
            journeyNodeId: cursor.getInt64(11),
            campaignType: cursor.getString(12)
        )
    }
}
