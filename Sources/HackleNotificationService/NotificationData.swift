import Foundation

final class NotificationData: Sendable {
    let imageUrl: String?

    init(imageUrl: String?) {
        self.imageUrl = imageUrl
    }
}
