import Foundation
@testable import Hackle

class MockPushTokenDataSource: PushTokenDataSource {
    
    var pushToken: String? = nil
    
    func getPushToken() -> String? {
        return pushToken
    }
}
