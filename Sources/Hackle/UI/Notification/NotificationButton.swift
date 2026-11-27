import Foundation

struct NotificationButton: Sendable {
    let clickAction: NotificationClickAction
    let link: String?
    let type: String?
}
