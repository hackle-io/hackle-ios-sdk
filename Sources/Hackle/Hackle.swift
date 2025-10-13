//
// Created by yong on 2020/12/22.
//

import Foundation
import UserNotifications

/// The main entry point for the Hackle SDK.
/// 
/// Initialize the SDK once in your application lifecycle using ``initialize(sdkKey:config:)`` or one of its variants,
/// then access the singleton instance through ``app()``.
@objc public class Hackle: NSObject {

    private static let queue = DispatchQueue(label: "io.hackle.InitializeQueue", qos: .utility)
    static let lock = ReadWriteLock(label: "io.hackle.HackleApp")
    static var instance: HackleApp?

    /// Initializes the Hackle SDK with the provided SDK key and configuration.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: {})
    }

    /// Initializes the Hackle SDK with the provided SDK key, configuration, and completion handler.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    ///   - completion: Completion handler called when initialization is complete
    @objc public static func initialize(sdkKey: String, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping () -> ()) {
        initialize(sdkKey: sdkKey, user: nil, config: config, completion: completion)
    }

    /// Initializes the Hackle SDK with the provided SDK key, user, and configuration.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - user: Initial user to set for the SDK. Can be nil
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT) {
        initialize(sdkKey: sdkKey, user: user, config: config, completion: {})
    }

    /// Initializes the Hackle SDK with the provided SDK key, user, configuration, and completion handler.
    ///
    /// - Parameters:
    ///   - sdkKey: Your Hackle SDK key
    ///   - user: Initial user to set for the SDK. Can be nil
    ///   - config: SDK configuration options. Defaults to ``HackleConfig/DEFAULT``
    ///   - completion: Completion handler called when initialization is complete
    @objc public static func initialize(sdkKey: String, user: User?, config: HackleConfig = HackleConfig.DEFAULT, completion: @escaping () -> ()) {
        lock.write {
            if instance != nil {
                readyToUse(completion: completion)
            } else {
                let app = HackleApp.create(sdkKey: sdkKey, config: config)
                app.initialize(user: user) {
                    ApplicationLifecycleObserver.shared.publishWillEnterForegroundIfNeeded()
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

    /// Returns a singleton instance of ``HackleApp``.
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

    /// Creates a new ``User`` instance with the specified parameters.
    ///
    /// - Parameters:
    ///   - id: User identifier
    ///   - userId: User ID
    ///   - deviceId: Device identifier
    ///   - identifiers: Additional user identifiers
    ///   - properties: User properties
    /// - Returns: A new User instance
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

    /// Creates a new ``Event`` instance with the specified key and properties.
    ///
    /// - Parameters:
    ///   - key: Event key
    ///   - properties: Event properties
    /// - Returns: A new Event instance
    @objc public static func event(key: String, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .properties(properties ?? [:])
            .build()
    }

    /// Creates a new ``Event`` instance with the specified key, value, and properties.
    ///
    /// - Parameters:
    ///   - key: Event key
    ///   - value: Event value
    ///   - properties: Event properties
    /// - Returns: A new Event instance
    @objc public static func event(key: String, value: Double, properties: [String: Any]? = nil) -> Event {
        Event.builder(key)
            .value(value)
            .properties(properties ?? [:])
            .build()
    }
}

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
        guard let notificationData = NotificationData.from(data: notificationContent.userInfo) else {
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
