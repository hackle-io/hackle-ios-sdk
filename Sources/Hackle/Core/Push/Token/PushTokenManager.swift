import Foundation

protocol PushTokenManager {
    func currentToken() -> PushToken?
}

class DefaultPushTokenManager: PushTokenManager, PushTokenListener, UserListener {

    private static let PUSH_TOKEN_KEY = "apns_token"

    private let repository: KeyValueRepository
    private let userManager: UserManager
    private let eventTracker: PushEventTracker

    init(repository: KeyValueRepository, userManager: UserManager, eventTracker: PushEventTracker) {
        self.repository = repository
        self.userManager = userManager
        self.eventTracker = eventTracker
    }

    func currentToken() -> PushToken? {
        guard let tokenValue = repository.getString(key: DefaultPushTokenManager.PUSH_TOKEN_KEY) else {
            return nil
        }
        return PushToken(platformType: .ios, providerType: .apn, value: tokenValue)
    }

    func onTokenRegistered(token: PushToken, timestamp: Date) {
        if token == currentToken() {
            return
        }
        repository.putString(key: DefaultPushTokenManager.PUSH_TOKEN_KEY, value: token.value)
        eventTracker.trackPushToken(pushToken: token, user: userManager.currentUser, timestamp: timestamp)
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        guard let token = currentToken() else {
            return
        }
        eventTracker.trackPushToken(pushToken: token, user: newUser, timestamp: timestamp)
    }
}
