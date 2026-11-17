import Foundation
import UserNotifications

enum NotificationCategoryHandler {
    static let ACTION_IDENTIFIER_PREFIX = "hackle_action_"

    static func category(notificationData: NotificationData) -> UNNotificationCategory? {
        guard let categoryId = notificationData.categoryId,
              !categoryId.isEmpty,
              !notificationData.buttonTitles.isEmpty else {
            return nil
        }
        let actions = notificationData.buttonTitles.enumerated().map { index, title in
            UNNotificationAction(identifier: "\(ACTION_IDENTIFIER_PREFIX)\(index)", title: title, options: [.foreground])
        }
        return UNNotificationCategory(identifier: categoryId, actions: actions, intentIdentifiers: [], options: [])
    }

    static func merge(categories: Set<UNNotificationCategory>, category: UNNotificationCategory) -> Set<UNNotificationCategory> {
        var merged = categories.filter { $0.identifier != category.identifier }
        merged.insert(category)
        return merged
    }

    static func handlePushCategory(
        notificationData: NotificationData,
        completion: @escaping (String?) -> Void
    ) {
        Log.info("handle push category action")
        guard let category = category(notificationData: notificationData) else {
            completion(nil)
            return
        }
        let categoryId = category.identifier
        let box = UncheckedSendableBox(category)
        let center = UncheckedSendableBox(UNUserNotificationCenter.current())
        let sink = UncheckedSendableBox(completion)
        center.value.getNotificationCategories { existing in
            center.value.setNotificationCategories(merge(categories: existing, category: box.value))
            center.value.getNotificationCategories { _ in
                sink.value(categoryId)
            }
        }
    }
}
