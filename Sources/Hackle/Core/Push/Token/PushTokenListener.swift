import Foundation

protocol PushTokenListener {
    func onTokenRegistered(token: PushToken, timestamp: Date)
}
