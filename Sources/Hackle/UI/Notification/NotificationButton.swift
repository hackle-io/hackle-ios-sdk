import Foundation

struct NotificationButton: Sendable {
    let type: String?
    let clickAction: NotificationClickAction
    let link: String?
}
