import Foundation

enum NotificationClickAction: String {
    case APP_OPEN = "APP_OPEN"
    case DEEP_LINK = "DEEP_LINK"
}

extension NotificationClickAction {
    static func from(
        rawValue: String?,
        defaultValue: NotificationClickAction = APP_OPEN
    ) -> NotificationClickAction {
        guard let rawValue = rawValue else {
            return defaultValue
        }
        guard let retValue = NotificationClickAction(rawValue: rawValue) else {
            return defaultValue
        }
        return retValue
    }
}
