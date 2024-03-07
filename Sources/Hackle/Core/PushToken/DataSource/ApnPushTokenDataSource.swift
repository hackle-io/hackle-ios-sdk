import Foundation

class ApnPushTokenDataSource: PushTokenDataSource {
    public static let shared = ApnPushTokenDataSource()
    
    private var pushToken: String? = nil
    
    func update(deviceToken: Data) {
        pushToken = deviceToken.hexString()
    }
    
    func getPushToken() -> String? {
        return pushToken
    }
}
