import Foundation
import UIKit

class HackleNotificationCenterDelegateProxy: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = HackleNotificationCenterDelegateProxy()
    private var swizzled = false
    
    func swizzle() {
        if swizzled {
            return
        }
        
        guard let notificationCenterDelegate = UNUserNotificationCenter.current().delegate else {
            UNUserNotificationCenter.current().delegate = self
            Log.debug("Successfully swizzling installed: UNUserNotificationCenterDelegate")
            return
        }
        
        if swizzleUserNotificationCenterWillPresentWithCompletionHandler(
            notificationCenterDelegate: notificationCenterDelegate
        ) {
            swizzled = true
            Log.debug("Successfully swizzling installed: UNUserNotificationCenterDelegate")
        } else {
            Log.debug("Swizzling failed: UNUserNotificationCenterDelegate")
        }
    }
    
    private func swizzleUserNotificationCenterWillPresentWithCompletionHandler(
        notificationCenterDelegate: UNUserNotificationCenterDelegate
    ) -> Bool {
        guard let notificationCenterDelegateClass: AnyClass = object_getClass(notificationCenterDelegate) else {
            return false
        }
        
        let targetMethodSelector = #selector(
            UNUserNotificationCenterDelegate
                .userNotificationCenter(_:willPresent:withCompletionHandler:)
        )
        let proxyMethodSelector = #selector(
            HackleNotificationCenterDelegateProxy.self
                .userNotificationCenter(_:willPresent:withCompletionHandler:)
        )
        return Swizzling.injectSelector(
            targetClass: notificationCenterDelegateClass,
            targetSelector: targetMethodSelector,
            proxyClass: notificationCenterDelegateClass,
            proxySelector: proxyMethodSelector
        )
    }
    
    @objc func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if Hackle.userNotificationCenter(
            center: center,
            willPresent: notification,
            withCompletionHandler: completionHandler
        ) {
            // Succefully processed notification
            // Automatically consumed completion handler
        } else {
            // Received not hackle notification or error
            if #available(iOS 14.0, *) {
                completionHandler([.list, .banner])
            } else {
                completionHandler([.alert])
            }
        }
    }
}
