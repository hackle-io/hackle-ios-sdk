import Foundation

enum NotificationClickAction: String {
    case appOpen = "APP_OPEN"
    case deepLink = "DEEP_LINK"
}

extension NotificationClickAction {
    static func from(
        rawValue: String?,
        defaultValue: NotificationClickAction = appOpen
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
