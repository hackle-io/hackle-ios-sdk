import Foundation
import UserNotifications

class NotificationData {
    let workspaceId: Int64
    let environmentId: Int64
    
    let pushMessageId: Int64?
    let pushMessageKey: Int64?
    let pushMessageExecutionId: Int64?
    let pushMessageDeliveryId: Int64?
    
    let showForeground: Bool
    let imageUrl: String?
    let clickAction: NotificationClickAction
    let link: String?
    
    init(
        workspaceId: Int64,
        environmentId: Int64,
        pushMessageId: Int64?,
        pushMessageKey: Int64?,
        pushMessageExecutionId: Int64?,
        pushMessageDeliveryId: Int64?,
        showForeground: Bool,
        imageUrl: String?,
        clickAction: NotificationClickAction,
        link: String?
    ) {
        self.workspaceId = workspaceId
        self.environmentId = environmentId
        self.pushMessageId = pushMessageId
        self.pushMessageKey = pushMessageKey
        self.pushMessageExecutionId = pushMessageExecutionId
        self.pushMessageDeliveryId = pushMessageDeliveryId
        self.showForeground = showForeground
        self.imageUrl = imageUrl
        self.clickAction = clickAction
        self.link = link
    }
}

extension NotificationData {
    static let KEY_HACKLE = "hackle"
    static let KEY_WORKSPACE_ID = "workspaceId"
    static let KEY_ENVIRONMENT_ID = "environmentId"
    static let KEY_PUSH_MESSAGE_ID = "pushMessageId"
    static let KEY_PUSH_MESSAGE_KEY = "pushMessageKey"
    static let KEY_PUSH_MESSAGE_EXECUTION_ID = "pushMessageExecutionId"
    static let KEY_PUSH_MESSAGE_DELIVERY_ID = "pushMessageDeliveryId"
    static let KEY_SHOW_FOREGROUND = "showForeground"
    static let KEY_IMAGE_URL = "imageUrl"
    static let KEY_CLICK_ACTION = "clickAction"
    static let KEY_LINK = "link"
    
    static func from(data: [AnyHashable: Any]) -> NotificationData? {
        guard let hackle = data[KEY_HACKLE] as? [AnyHashable: Any] else {
            return nil
        }
        
        do {
            return NotificationData(
                workspaceId: try (hackle[KEY_WORKSPACE_ID] as? Int64).requireNotNil(),
                environmentId: try (hackle[KEY_ENVIRONMENT_ID] as? Int64).requireNotNil(),
                pushMessageId: hackle[KEY_PUSH_MESSAGE_ID] as? Int64,
                pushMessageKey: hackle[KEY_PUSH_MESSAGE_KEY] as? Int64,
                pushMessageExecutionId: hackle[KEY_PUSH_MESSAGE_EXECUTION_ID] as? Int64,
                pushMessageDeliveryId: hackle[KEY_PUSH_MESSAGE_DELIVERY_ID] as? Int64,
                showForeground: hackle[KEY_SHOW_FOREGROUND] as? Bool ?? false,
                imageUrl: hackle[KEY_IMAGE_URL] as? String,
                clickAction: NotificationClickAction.from(
                    rawValue: hackle[KEY_CLICK_ACTION] as? String
                ),
                link: hackle[KEY_LINK] as? String
            )
        } catch {
            return nil
        }
    }
}

extension NotificationData {
    func toEntity(timestamp: Date) -> NotificationEntity {
        return NotificationEntity(
            notificationId: 0,
            workspaceId: workspaceId,
            environmentId: environmentId,
            pushMessageId: pushMessageId,
            pushMessageKey: pushMessageKey,
            pushMessageExecutionId: pushMessageExecutionId,
            pushMessageDeliveryId: pushMessageDeliveryId,
            clickTimestamp: timestamp
        )
    }
}
