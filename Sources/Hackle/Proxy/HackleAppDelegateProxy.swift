import Foundation
import UIKit

class HackleAppDelegateProxy: NSObject {
    public static let shared = HackleAppDelegateProxy()
    private var swizzled = false
    
    func swizzle() {
        if swizzled {
            return
        }
        
        guard let application = UIUtils.application,
              let appDelegate = application.delegate else {
            Log.debug("Cannot find UIApplicationDelegate.")
            return
        }
        
        application.registerForRemoteNotifications()
        
        if swizzleDidRegisterForRemoteNotificationsWithDeviceToken(appDelegate: appDelegate) {
            swizzled = true
            Log.debug("Successfully swizzling installed: UIApplicationDelegate")
        } else {
            Log.debug("Swizzling failed: UIApplicationDelegate")
        }
    }
    
    private func swizzleDidRegisterForRemoteNotificationsWithDeviceToken(appDelegate: UIApplicationDelegate) -> Bool {
        guard let appDelegateClass: AnyClass = object_getClass(appDelegate) else {
            return false
        }
        
        let targetSelector = #selector(
            UIApplicationDelegate
                .application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
        )
        let proxySelector = #selector(
            HackleAppDelegateProxy.self
                .application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
        )
        return Swizzling.injectSelector(
            targetClass: appDelegateClass,
            targetSelector: targetSelector,
            proxyClass: HackleAppDelegateProxy.self,
            proxySelector: proxySelector
        )
    }
    
    @objc func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        ApnPushTokenDataSource.shared.update(deviceToken: deviceToken)
    }
}
