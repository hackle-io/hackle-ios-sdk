import Foundation
import UserNotifications

/// Rich push notification support for Notification Service Extension targets.
///
/// This module depends only on Foundation and UserNotifications and does not expose any other Hackle feature.
@objc public final class HackleNotificationService: NSObject {

    private override init() {}

    /// Handles rich notifications with media attachments.
    ///
    /// - Parameters:
    ///   - request: The notification request
    ///   - contentHandler: Handler to process the notification content
    /// - Returns: True if the notification was handled by Hackle, false otherwise
    @objc static public func handleRichNotification(
        request: UNNotificationRequest,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard let baseNotificationContent: UNMutableNotificationContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return false
        }

        return resolveRichNotificationContent(notificationContent: baseNotificationContent, completion: { hackleNotificationContent in
            contentHandler(hackleNotificationContent)
        })
    }

    /// Resolves rich notification content from mutable content.
    ///
    /// - Parameters:
    ///   - notificationContent: The mutable notification content
    ///   - completion: Completion handler with resolved content
    /// - Returns: True if the notification was handled by Hackle, false otherwise
    @objc static public func resolveRichNotificationContent(
        notificationContent: UNMutableNotificationContent,
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) -> Bool {
        guard let notificationData = NotificationData.from(data: notificationContent.userInfo) else {
            return false
        }

        NotificationImageHandler.handlePushImage(notificationData: notificationData) { attachment in
            if let attachment = attachment {
                notificationContent.attachments = [attachment]
            }

            completion(notificationContent)
        }

        return true
    }
}
