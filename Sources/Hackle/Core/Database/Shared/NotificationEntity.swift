import Foundation

class NotificationEntity {
    let notificationId: Int64
    
    let workspaceId: Int64
    let environmentId: Int64
    
    let pushMessageId: Int64?
    let pushMessageKey: Int64?
    let pushMessageExecutionId: Int64?
    let pushMessageDeliveryId: Int64?
    
    let clickTimestamp: Date
    
    init(
        notificationId: Int64,
        workspaceId: Int64,
        environmentId: Int64,
        pushMessageId: Int64?,
        pushMessageKey: Int64?,
        pushMessageExecutionId: Int64?,
        pushMessageDeliveryId: Int64?,
        clickTimestamp: Date
    ) {
        self.notificationId = notificationId
        self.workspaceId = workspaceId
        self.environmentId = environmentId
        self.pushMessageId = pushMessageId
        self.pushMessageKey = pushMessageKey
        self.pushMessageExecutionId = pushMessageExecutionId
        self.pushMessageDeliveryId = pushMessageDeliveryId
        self.clickTimestamp = clickTimestamp
    }
}

extension NotificationEntity {
    static let TABLE_NAME = "notifications"
    
    static let COLUMN_NOTIFICATION_ID = "notification_id"
    static let COLUMN_WORKSPACE_ID = "workspace_id"
    static let COLUMN_ENVIRONMENT_ID = "environment_id"
    static let COLUMN_PUSH_MESSAGE_ID = "push_message_id"
    static let COLUMN_PUSH_MESSAGE_KEY = "push_message_key"
    static let COLUMN_PUSH_MESSAGE_EXECUTION_ID = "push_message_execution_id"
    static let COLUMN_PUSH_MESSAGE_DELIVERY_ID = "push_message_delivery_id"
    static let COLUMN_CLICK_TIMESTAMP = "click_timestamp"
    
    static let CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (" +
            "\(COLUMN_NOTIFICATION_ID) INTEGER PRIMARY KEY AUTOINCREMENT," +
            "\(COLUMN_WORKSPACE_ID) INTEGER NOT NULL," +
            "\(COLUMN_ENVIRONMENT_ID) INTEGER NOT NULL," +
            "\(COLUMN_PUSH_MESSAGE_ID) INTEGER," +
            "\(COLUMN_PUSH_MESSAGE_KEY) INTEGER," +
            "\(COLUMN_PUSH_MESSAGE_EXECUTION_ID) INTEGER," +
            "\(COLUMN_PUSH_MESSAGE_DELIVERY_ID) INTEGER," +
            "\(COLUMN_CLICK_TIMESTAMP) INTEGER" +
        ")"
    
    static func from(cursor: SQLiteCursor) -> NotificationEntity {
        return NotificationEntity(
            notificationId: cursor.getInt64(0),
            workspaceId: cursor.getInt64(1),
            environmentId: cursor.getInt64(2),
            pushMessageId: cursor.getInt64(3),
            pushMessageKey: cursor.getInt64(4),
            pushMessageExecutionId: cursor.getInt64(5),
            pushMessageDeliveryId: cursor.getInt64(6),
            clickTimestamp: Date(timeIntervalSince1970: cursor.getDouble(7))
        )
    }
}
