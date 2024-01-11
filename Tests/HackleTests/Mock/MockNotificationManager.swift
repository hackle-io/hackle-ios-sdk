import Foundation
@testable import Hackle

class MockNotificationManager: NotificationManager {
    
    private var _registeredPushToken: String? = nil
    var registeredPushToken: String? {
        get { return _registeredPushToken }
    }
    
    func setPushToken(deviceToken: Data, timestamp: Date) {
        let deviceTokenString = deviceToken.hexString()
        _registeredPushToken = deviceTokenString
    }
    
    func flush() {
        
    }
    
    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        
    }
    
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        
    }
}
