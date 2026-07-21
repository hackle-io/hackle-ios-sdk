//
//  Hackle+Notification.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/6/26.
//

import Foundation
import UserNotifications

extension Hackle {
    /// Sets the push notification device token.
    ///
    /// - Parameter deviceToken: The device token for push notifications
    @objc static public func setPushToken(_ deviceToken: Data) {
        DefaultPushTokenRegistry.shared.register(token: PushToken.of(value: deviceToken), timestamp: Date())
    }
}

extension Hackle {
    /// Handles notification presentation in foreground.
    ///
    /// - Parameters:
    ///   - center: The notification center
    ///   - notification: The notification to be presented
    ///   - completionHandler: Handler to determine presentation options
    /// - Returns: True if the notification was handled by Hackle, false otherwise
    @objc static public func userNotificationCenter(
        center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) -> Bool {
        if let notificationData = NotificationData.from(data: notification.request.content.userInfo) {
            Log.info("Notification data received in foreground: \(notificationData.showForeground)")
            if (notificationData.showForeground) {
                if #available(iOS 14.0, *) {
                    completionHandler([.list, .banner])
                } else {
                    completionHandler([.alert])
                }
            }
            return true
        } else {
            return false
        }
    }

    /// Handles notification tap responses.
    ///
    /// - Parameters:
    ///   - response: The notification response
    ///   - handleAction: Whether to automatically handle notification actions. Defaults to true
    /// - Returns: ``HackleNotification`` if the notification was from Hackle, nil otherwise
    @objc static public func handleNotification(
        response: UNNotificationResponse,
        handleAction: Bool = true
    ) -> HackleNotification? {
        guard let notificationData = NotificationData.from(data: response.notification.request.content.userInfo) else {
            return nil
        }
        
        NotificationHandler.shared.trackPushClickEvent(notificationData: notificationData)

        if handleAction {
            NotificationHandler.shared.handlePushClickAction(notificationData: notificationData)
        }
        
        return notificationData
    }
    
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
        
        return handleRichNotification(notificationContent: baseNotificationContent, contentHandler: contentHandler)
    }
    
    /// Handles rich notifications with mutable content.
    ///
    /// - Parameters:
    ///   - notificationContent: The mutable notification content
    ///   - contentHandler: Handler to process the notification content
    /// - Returns: True if the notification was handled by Hackle, false otherwise
    @objc static public func handleRichNotification(
        notificationContent: UNMutableNotificationContent,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard NotificationData.from(data: notificationContent.userInfo) != nil else {
            return false
        }

        return resolveRichNotificationContent(notificationContent: notificationContent, completion: { hackleNotificationContent in
            contentHandler(hackleNotificationContent)
        })
    }
    
    /// Resolves rich notification content from a notification request.
    ///
    /// - Parameters:
    ///   - request: The notification request
    ///   - completion: Completion handler with resolved content
    /// - Returns: True if the notification was handled by Hackle, false otherwise
    @objc static public func resolveRichNotificationContent(
        request: UNNotificationRequest,
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) -> Bool {
        guard let baseNotificationContent: UNMutableNotificationContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return false
        }
        
        return resolveRichNotificationContent(notificationContent: baseNotificationContent, completion: completion)
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
        
        // NOTE: use dispatch group when add another attachment, and etc...
        NotificationHandler.shared.handlePushImage(notificationData: notificationData) { attachment in
            if let attachment = attachment {
                notificationContent.attachments = [attachment]
            }
            
            completion(notificationContent)
        }
        
        return true
    }

    /// Handles notification responses
    ///
    /// - Parameters:
    ///   - center: The notification center
    ///   - response: The notification response
    ///   - completionHandler: Completion handler
    /// - Returns: True if the notification was handled by Hackle, false otherwise
    @available(*, deprecated, message: "Use handleClickNotification(UNNotificationResponse, Bool) instead.")
    @objc static public func userNotificationCenter(
        center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) -> Bool {
        if handleNotification(response: response) == nil {
            return false
        }
        completionHandler()
        return true
    }
}
