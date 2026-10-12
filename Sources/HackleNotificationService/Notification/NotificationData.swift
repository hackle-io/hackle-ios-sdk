import Foundation

final class NotificationData: Sendable {
    let imageUrl: String?

    init(imageUrl: String?) {
        self.imageUrl = imageUrl
    }
}

extension NotificationData {
    static let KEY_HACKLE = "hackle"
    static let KEY_WORKSPACE_ID = "workspaceId"
    static let KEY_ENVIRONMENT_ID = "environmentId"
    static let KEY_IMAGE_URL = "imageUrl"

    static func from(data: [AnyHashable: Any]) -> NotificationData? {
        guard let hackle = data[KEY_HACKLE] as? [AnyHashable: Any] else {
            return nil
        }
        guard hackle[KEY_WORKSPACE_ID].asIntOrNil() != nil,
              hackle[KEY_ENVIRONMENT_ID].asIntOrNil() != nil else {
            return nil
        }
        return NotificationData(imageUrl: hackle[KEY_IMAGE_URL] as? String)
    }
}
