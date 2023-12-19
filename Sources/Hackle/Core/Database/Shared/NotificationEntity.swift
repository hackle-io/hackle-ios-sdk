import Foundation

class NotificationEntity {
    let notificationId: Int64
    let workspaceId: Int
    let environmentId: Int
    let pushMessageId: Int
    let clickAction: String
    let clickTimestamp: Date
    let link: String?
    
    init(
        notificationId: Int64,
        workspaceId: Int,
        environmentId: Int,
        pushMessageId: Int,
        clickAction: String,
        clickTimestamp: Date,
        link: String?
    ) {
        self.notificationId = notificationId
        self.workspaceId = workspaceId
        self.environmentId = environmentId
        self.pushMessageId = pushMessageId
        self.clickAction = clickAction
        self.clickTimestamp = clickTimestamp
        self.link = link
    }
}

extension NotificationEntity {
    static let TABLE_NAME = "notifications"
    static let COLUMN_NOTIFICATION_ID = "notification_id"
    static let COLUMN_WORKSPACE_ID = "workspace_id"
    static let COLUMN_ENVIRONMENT_ID = "environment_id"
    static let COLUMN_PUSH_MESSAGE_ID = "push_message_id"
    static let COLUMN_CLICK_ACTION = "click_action"
    static let COLUMN_CLICK_TIMESTAMP = "click_timestamp"
    static let COLUMN_LINK = "link"
    
    static let CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (" +
            "\(COLUMN_NOTIFICATION_ID) INTEGER PRIMARY KEY AUTOINCREMENT," +
            "\(COLUMN_WORKSPACE_ID) INTEGER NOT NULL," +
            "\(COLUMN_ENVIRONMENT_ID) INTEGER NOT NULL," +
            "\(COLUMN_PUSH_MESSAGE_ID) INTEGER NOT NULL," +
            "\(COLUMN_CLICK_ACTION) TEXT," +
            "\(COLUMN_CLICK_TIMESTAMP) INTEGER," +
            "\(COLUMN_LINK) TEXT" +
        ")"
    
    static func from(cursor: SQLiteCursor) -> NotificationEntity {
        return NotificationEntity(
            notificationId: cursor.getInt64(0),
            workspaceId: cursor.getInt(1),
            environmentId: cursor.getInt(2),
            pushMessageId: cursor.getInt(3),
            clickAction: cursor.getString(4),
            clickTimestamp: Date(timeIntervalSince1970: cursor.getDouble(5)),
            link: cursor.getString(6)
        )
    }
}
