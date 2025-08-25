//
// Created by yong on 2020/12/22.
//

import Foundation
import UserNotifications

@objc public class Hackle: NSObject {

    private static let queue = DispatchQueue(label: "io.hackle.InitializeQueue", qos: .utility)
    static let lock = ReadWriteLock(label: "io.hackle.HackleApp")
    static var instance: HackleApp?

    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: {})
    }

    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping () -> ()) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: completion)
    }

    @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: user, config: config, completion: {})
    }

    @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping () -> ()) {
        lock.write {
            if instance != nil {
                readyToUse(completion: completion)
            } else {
                let app = HackleApp.create(sdkKey: sdkKey, config: config)
                app.initialize(user: user) {
                    readyToUse(completion: completion)
                }
                instance = app
            }
        }
    }

    private static func readyToUse(completion: @escaping () -> ()) {
        queue.async {
            completion()
        }
    }

    ///
    /// Returns a singleton instance of `HackleApp`
    ///
    /// - Returns: The HackleApp instance or `nil` if not initialized
    @objc public static func app() -> HackleApp? {
        lock.write {
            if instance == nil {
                Log.error("HackleApp is not initialized. Make sure to call Hackle.initialize() first")
            }
            return instance
        }
    }
}

extension Hackle {

    @objc public static func user(
        id: String? = nil,
        userId: String? = nil,
        deviceId: String? = nil,
        identifiers: [String: String]? = nil,
        properties: [String: Any]? = nil
    ) -> User {
        User.builder()
            .id(id)
            .userId(userId)
            .deviceId(deviceId)
            .identifiers(identifiers ?? [:])
            .properties(properties ?? [:])
            .build()
    }

    @objc public static func event(key: String, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .properties(properties ?? [:])
            .build()
    }

    @objc public static func event(key: String, value: Double, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .value(value)
            .properties(properties ?? [:])
            .build()
    }
}

extension Hackle {
    @objc static public func setPushToken(_ deviceToken: Data) {
        DefaultPushTokenRegistry.shared.register(token: PushToken.of(value: deviceToken), timestamp: Date())
    }
}

extension Hackle {
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
    
    @objc static public func handleRichNotification(
        request: UNNotificationRequest,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard let baseNotificationContent: UNMutableNotificationContent = (request.content as? UNMutableNotificationContent) else {
            return false
        }
        
        return handleRichNotification(notificationContent: baseNotificationContent, contentHandler: contentHandler)
    }
    
    @objc static public func handleRichNotification(
        notificationContent: UNMutableNotificationContent,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard let notificationData = NotificationData.from(data: notificationContent.userInfo) else {
            return false
        }
        
        return resolveRichNotificationContent(notificationContent: notificationContent, completion: {
            contentHandler($0)
        })
    }
    
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
