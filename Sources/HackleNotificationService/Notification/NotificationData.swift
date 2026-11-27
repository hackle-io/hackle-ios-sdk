import Foundation

final class NotificationData: Sendable {
    let imageUrl: String?
    let categoryId: String?
    let buttonTitles: [String]

    init(imageUrl: String?, categoryId: String? = nil, buttonTitles: [String] = []) {
        self.imageUrl = imageUrl
        self.categoryId = categoryId
        self.buttonTitles = buttonTitles
    }
}

extension NotificationData {
    static let KEY_HACKLE = "hackle"
    static let KEY_WORKSPACE_ID = "workspaceId"
    static let KEY_ENVIRONMENT_ID = "environmentId"
    static let KEY_IMAGE_URL = "imageUrl"
    static let KEY_BUTTONS = "buttons"
    static let KEY_CATEGORY_ID = "categoryId"
    static let KEY_ITEMS = "items"
    static let KEY_TITLE = "title"

    static func from(data: [AnyHashable: Any]) -> NotificationData? {
        guard let hackle = data[KEY_HACKLE] as? [AnyHashable: Any] else {
            return nil
        }
        guard hackle[KEY_WORKSPACE_ID].asIntOrNil() != nil,
              hackle[KEY_ENVIRONMENT_ID].asIntOrNil() != nil else {
            return nil
        }
        let buttons = hackle[KEY_BUTTONS] as? [AnyHashable: Any]
        return NotificationData(
            imageUrl: hackle[KEY_IMAGE_URL] as? String,
            categoryId: buttons?[KEY_CATEGORY_ID] as? String,
            buttonTitles: buttonTitles(buttons)
        )
    }

    private static func buttonTitles(_ buttons: [AnyHashable: Any]?) -> [String] {
        guard let items = buttons?[KEY_ITEMS] as? [Any] else {
            return []
        }
        var titles = [String]()
        for item in items {
            guard let title = (item as? [AnyHashable: Any])?[KEY_TITLE] as? String else {
                return []
            }
            titles.append(title)
        }
        return titles
    }
}
