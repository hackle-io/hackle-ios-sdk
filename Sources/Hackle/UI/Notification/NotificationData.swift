import Foundation
import UserNotifications

class NotificationData: HackleNotification {
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
    
    let journeyId: Int64?
    let journeyKey: Int64?
    let journeyNodeId: Int64?
    let campaignType: String?
    
    let debug: Bool
    
    var type: HackleNotificationClickActionType {
        switch clickAction {
        case .appOpen:
            return .appOpen
        case .deepLink:
            return .deepLink
        }
    }
    
    var deepLink: String? {
        switch clickAction {
        case .appOpen:
            return nil
        case .deepLink:
            return link
        }
    }
    
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
        link: String?,
        journeyId: Int64?,
        journeyKey: Int64?,
        journeyNodeId: Int64?,
        campaignType: String?,
        debug: Bool
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
        self.journeyId = journeyId
        self.journeyKey = journeyKey
        self.journeyNodeId = journeyNodeId
        self.campaignType = campaignType
        self.debug = debug
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
    static let KEY_JOURNEY_ID = "journeyId"
    static let KEY_JOURNEY_KEY = "journeyKey"
    static let KEY_JOURNEY_NODE_ID = "journeyNodeId"
    static let KEY_CAMPAIGN_TYPE = "campaignType"
    static let KEY_DEBUG = "debug"
    
    static func from(data: [AnyHashable: Any]) -> NotificationData? {
        guard let hackle = data[KEY_HACKLE] as? [AnyHashable: Any] else {
            return nil
        }
        
        do {
            return NotificationData(
                workspaceId: try (hackle[KEY_WORKSPACE_ID].asIntOrNil()).requireNotNil(),
                environmentId: try (hackle[KEY_ENVIRONMENT_ID].asIntOrNil()).requireNotNil(),
                pushMessageId: hackle[KEY_PUSH_MESSAGE_ID].asIntOrNil(),
                pushMessageKey: hackle[KEY_PUSH_MESSAGE_KEY].asIntOrNil(),
                pushMessageExecutionId: hackle[KEY_PUSH_MESSAGE_EXECUTION_ID].asIntOrNil(),
                pushMessageDeliveryId: hackle[KEY_PUSH_MESSAGE_DELIVERY_ID].asIntOrNil(),
                showForeground: hackle[KEY_SHOW_FOREGROUND] as? Bool ?? false,
                imageUrl: hackle[KEY_IMAGE_URL] as? String,
                clickAction: NotificationClickAction.from(
                    rawValue: hackle[KEY_CLICK_ACTION] as? String
                ),
                link: hackle[KEY_LINK] as? String,
                journeyId: hackle[KEY_JOURNEY_ID].asIntOrNil(),
                journeyKey: hackle[KEY_JOURNEY_KEY].asIntOrNil(),
                journeyNodeId: hackle[KEY_JOURNEY_NODE_ID].asIntOrNil(),
                campaignType: hackle[KEY_CAMPAIGN_TYPE] as? String,
                debug: hackle[KEY_DEBUG] as? Bool ?? false
            )
        } catch {
            return nil
        }
    }
}
