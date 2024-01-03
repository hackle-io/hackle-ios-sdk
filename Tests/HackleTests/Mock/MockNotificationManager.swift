import Foundation
@testable import Hackle

class MockNotificationManager: NotificationManager {
    
    private var _apnsToken: String? = nil
    var apnsToken: String? {
        get { return _apnsToken }
    }
    
    func setAPNSToken(deviceToken: Data, timestamp: Date) {
        let deviceTokenString = deviceToken
            .map { String(format: "%.2hhx", $0) }
            .joined()
        _apnsToken = deviceTokenString
    }
    
    func flush() {
        
    }
    
    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        
    }
    
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        
    }
    
    
}
