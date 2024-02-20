import Foundation
@testable import Hackle

class MockPushTokenManager: PushTokenManager {
    var registeredPushToken: String? = nil
    
    func initialize() {
        
    }
    
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        
    }
    
    func setPushToken(pushToken: String, timestamp: Date) {
        
    }
}
