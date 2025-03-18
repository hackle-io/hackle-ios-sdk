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

    enum Column: String {
        case historyId = "history_id"
        case workspaceId = "workspace_id"
        case environmentId = "environment_id"
        case pushMessageId = "push_message_id"
        case pushMessageKey = "push_message_key"
        case pushMessageExecutionId = "push_message_execution_id"
        case pushMessageDeliveryId = "push_message_delivery_id"
        case timestamp = "timestamp"
        case debug = "debug"
        case journeyId = "journey_id"
        case journeyKey = "journey_key"
        case journeyNodeId = "journey_node_id"
        case campaignType = "campaign_type"
        
        var index: Int32 {
            switch self {
            case .historyId: return 0
            case .workspaceId: return 1
            case .environmentId: return 2
            case .pushMessageId: return 3
            case .pushMessageKey: return 4
            case .pushMessageExecutionId: return 5
            case .pushMessageDeliveryId: return 6
            case .timestamp: return 7
            case .debug: return 8
            case .journeyId: return 9
            case .journeyKey: return 10
            case .journeyNodeId: return 11
            case .campaignType: return 12
            }
        }
    }
    
    static let CREATE_TABLE_V1 =
        "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (" +
            "\(Column.historyId.rawValue) INTEGER PRIMARY KEY AUTOINCREMENT," +
            "\(Column.workspaceId.rawValue) INTEGER NOT NULL," +
            "\(Column.environmentId.rawValue) INTEGER NOT NULL," +
            "\(Column.pushMessageId.rawValue) INTEGER," +
            "\(Column.pushMessageKey.rawValue) INTEGER," +
            "\(Column.pushMessageExecutionId.rawValue) INTEGER," +
            "\(Column.pushMessageDeliveryId.rawValue) INTEGER," +
            "\(Column.timestamp.rawValue) string," +
            "\(Column.debug.rawValue) INTEGER" +
        ")"
    
    static let CREATE_LATEST_TABLE =
        "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (" +
            "\(Column.historyId.rawValue) INTEGER PRIMARY KEY AUTOINCREMENT," +
            "\(Column.workspaceId.rawValue) INTEGER NOT NULL," +
            "\(Column.environmentId.rawValue) INTEGER NOT NULL," +
            "\(Column.pushMessageId.rawValue) INTEGER," +
            "\(Column.pushMessageKey.rawValue) INTEGER," +
            "\(Column.pushMessageExecutionId.rawValue) INTEGER," +
            "\(Column.pushMessageDeliveryId.rawValue) INTEGER," +
            "\(Column.timestamp.rawValue) string," +
            "\(Column.debug.rawValue) INTEGER," +
            "\(Column.journeyId.rawValue) INTEGER," +
            "\(Column.journeyKey.rawValue) INTEGER," +
            "\(Column.journeyNodeId.rawValue) INTEGER," +
            "\(Column.campaignType.rawValue) TEXT" +
        ")"
    
    static let DROP_TABLE =
        "DROP TABLE IF EXISTS \(TABLE_NAME)"

    static let ADD_JOURNEY_ID =
        "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(Column.journeyId.rawValue) INTEGER"

    static let ADD_JOURNEY_KEY =
        "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(Column.journeyKey.rawValue) INTEGER"

    static let ADD_JOURNEY_NODE_ID =
        "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(Column.journeyNodeId.rawValue) INTEGER"

    static let ADD_CAMPAIGN_TYPE =
        "ALTER TABLE \(TABLE_NAME) ADD COLUMN \(Column.campaignType.rawValue) TEXT"
    
    static let TABLE_EXISTS =
        "SELECT EXISTS(SELECT 1 FROM sqlite_master WHERE type='table' AND name='\(TABLE_NAME)')"
    
    static let INSERT_TABLE =
        "INSERT INTO \(NotificationHistoryEntity.TABLE_NAME) (" +
            "\(NotificationHistoryEntity.Column.workspaceId.rawValue)," +
            "\(NotificationHistoryEntity.Column.environmentId.rawValue)," +
            "\(NotificationHistoryEntity.Column.pushMessageId.rawValue)," +
            "\(NotificationHistoryEntity.Column.pushMessageKey.rawValue)," +
            "\(NotificationHistoryEntity.Column.pushMessageExecutionId.rawValue)," +
            "\(NotificationHistoryEntity.Column.pushMessageDeliveryId.rawValue)," +
            "\(NotificationHistoryEntity.Column.timestamp.rawValue)," +
            "\(NotificationHistoryEntity.Column.debug.rawValue)," +
            "\(NotificationHistoryEntity.Column.journeyId.rawValue)," +
            "\(NotificationHistoryEntity.Column.journeyKey.rawValue)," +
            "\(NotificationHistoryEntity.Column.journeyNodeId.rawValue)," +
            "\(NotificationHistoryEntity.Column.campaignType.rawValue)" +
        ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    
    static func bind(statement: SQLiteStatement, data: NotificationData, timestamp: Date) throws {
        try statement.bindInt(index: Column.workspaceId.index, value: data.workspaceId)
        try statement.bindInt(index: Column.environmentId.index, value: data.environmentId)
        try statement.bindInt(index: Column.pushMessageId.index, value: data.pushMessageId)
        try statement.bindInt(index: Column.pushMessageKey.index, value: data.pushMessageKey)
        try statement.bindInt(index: Column.pushMessageExecutionId.index, value: data.pushMessageExecutionId)
        try statement.bindInt(index: Column.pushMessageDeliveryId.index, value: data.pushMessageDeliveryId)
        try statement.bindDouble(index: Column.timestamp.index, value: timestamp.timeIntervalSince1970)
        try statement.bindBool(index: Column.debug.index, value: data.debug)
        try statement.bindInt(index: Column.journeyId.index, value: data.journeyId)
        try statement.bindInt(index: Column.journeyKey.index, value: data.journeyKey)
        try statement.bindInt(index: Column.journeyNodeId.index, value: data.journeyNodeId)
        try statement.bindString(index: Column.campaignType.index, value: data.campaignType)
        try statement.execute()
    }
    
    static func from(cursor: SQLiteCursor) -> NotificationHistoryEntity {
        return NotificationHistoryEntity(
            historyId: cursor.getInt64(Column.historyId.index),
            workspaceId: cursor.getInt64(Column.workspaceId.index),
            environmentId: cursor.getInt64(Column.environmentId.index),
            pushMessageId: cursor.getInt64(Column.pushMessageId.index),
            pushMessageKey: cursor.getInt64(Column.pushMessageKey.index),
            pushMessageExecutionId: cursor.getInt64(Column.pushMessageExecutionId.index),
            pushMessageDeliveryId: cursor.getInt64(Column.pushMessageDeliveryId.index),
            timestamp: Date(timeIntervalSince1970: cursor.getDouble(Column.timestamp.index)),
            debug: cursor.getBool(Column.debug.index),
            journeyId: cursor.getInt64(Column.journeyId.index),
            journeyKey: cursor.getInt64(Column.journeyKey.index),
            journeyNodeId: cursor.getInt64(Column.journeyNodeId.index),
            campaignType: cursor.getString(Column.campaignType.index)
        )
    }
}
