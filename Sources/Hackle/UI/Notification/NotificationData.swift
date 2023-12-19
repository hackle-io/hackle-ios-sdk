import Foundation
import UserNotifications

class NotificationData {
    let workspaceId: Int
    let environmentId: Int
    let pushMessageId: Int
    let showForeground: Bool
    let imageUrl: String?
    let clickAction: NotificationClickAction
    let link: String?
    
    init(
        workspaceId: Int,
        environmentId: Int,
        pushMessageId: Int,
        showForeground: Bool,
        imageUrl: String?,
        clickAction: NotificationClickAction,
        link: String?
    ) {
        self.workspaceId = workspaceId
        self.environmentId = environmentId
        self.pushMessageId = pushMessageId
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
                workspaceId: try (hackle[KEY_WORKSPACE_ID] as? Int).requireNotNil(),
                environmentId: try (hackle[KEY_ENVIRONMENT_ID] as? Int).requireNotNil(),
                pushMessageId: try (hackle[KEY_PUSH_MESSAGE_ID] as? Int).requireNotNil(),
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
