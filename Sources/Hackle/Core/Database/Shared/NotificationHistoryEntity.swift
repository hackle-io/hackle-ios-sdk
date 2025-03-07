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
        journeyId: Int64?,
        journeyKey: Int64?,
        journeyNodeId: Int64?,
        campaignType: String?,
        timestamp: Date,
        debug: Bool
    ) {
        self.historyId = historyId
        self.workspaceId = workspaceId
        self.environmentId = environmentId
        self.pushMessageId = pushMessageId
        self.pushMessageKey = pushMessageKey
        self.pushMessageExecutionId = pushMessageExecutionId
        self.pushMessageDeliveryId = pushMessageDeliveryId
        self.journeyId = journeyId
        self.journeyKey = journeyKey
        self.journeyNodeId = journeyNodeId
        self.campaignType = campaignType
        self.timestamp = timestamp
        self.debug = debug
    }
}

extension NotificationHistoryEntity {
    static let TABLE_NAME = "notification_histories"
    
    static let COLUMN_HISTORY_ID = "history_id"
    static let COLUMN_WORKSPACE_ID = "workspace_id"
    static let COLUMN_ENVIRONMENT_ID = "environment_id"
    static let COLUMN_PUSH_MESSAGE_ID = "push_message_id"
    static let COLUMN_PUSH_MESSAGE_KEY = "push_message_key"
    static let COLUMN_PUSH_MESSAGE_EXECUTION_ID = "push_message_execution_id"
    static let COLUMN_PUSH_MESSAGE_DELIVERY_ID = "push_message_delivery_id"
    static let COLUMN_JOURNEY_ID = "journey_id"
    static let COLUMN_JOURNEY_KEY = "journey_key"
    static let COLUMN_JOURNEY_NODE_ID = "journey_node_id"
    static let COLUMN_CAMPAIGN_TYPE = "campaign_type"
    static let COLUMN_TIMESTAMP = "timestamp"
    static let COLUMN_DEBUG = "debug"
    
    static let CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (" +
            "\(COLUMN_HISTORY_ID) INTEGER PRIMARY KEY AUTOINCREMENT," +
            "\(COLUMN_WORKSPACE_ID) INTEGER NOT NULL," +
            "\(COLUMN_ENVIRONMENT_ID) INTEGER NOT NULL," +
            "\(COLUMN_PUSH_MESSAGE_ID) INTEGER," +
            "\(COLUMN_PUSH_MESSAGE_KEY) INTEGER," +
            "\(COLUMN_PUSH_MESSAGE_EXECUTION_ID) INTEGER," +
            "\(COLUMN_PUSH_MESSAGE_DELIVERY_ID) INTEGER," +
            "\(COLUMN_JOURNEY_ID) INTEGER," +
            "\(COLUMN_JOURNEY_KEY) INTEGER," +
            "\(COLUMN_JOURNEY_NODE_ID) INTEGER," +
            "\(COLUMN_CAMPAIGN_TYPE) TEXT," +
            "\(COLUMN_TIMESTAMP) INTEGER," +
            "\(COLUMN_DEBUG) INTEGER" +
        ")"
    
    static func from(cursor: SQLiteCursor) -> NotificationHistoryEntity {
        return NotificationHistoryEntity(
            historyId: cursor.getInt64(0),
            workspaceId: cursor.getInt64(1),
            environmentId: cursor.getInt64(2),
            pushMessageId: cursor.getInt64(3),
            pushMessageKey: cursor.getInt64(4),
            pushMessageExecutionId: cursor.getInt64(5),
            pushMessageDeliveryId: cursor.getInt64(6),
            journeyId: cursor.getInt64(7),
            journeyKey: cursor.getInt64(8),
            journeyNodeId: cursor.getInt64(9),
            campaignType: cursor.getString(10),
            timestamp: Date(timeIntervalSince1970: cursor.getDouble(11)),
            debug: cursor.getBool(12)
        )
    }
}
