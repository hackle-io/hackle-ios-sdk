import Foundation

protocol PushTokenManager {
    func currentToken() -> PushToken?
}

class DefaultPushTokenManager: PushTokenManager, PushTokenListener, UserListener {

    private static let PUSH_TOKEN_KEY = "apns_token"

    private let core: HackleCore
    private let repository: KeyValueRepository
    private let userManager: UserManager

    init(core: HackleCore, repository: KeyValueRepository, userManager: UserManager) {
        self.core = core
        self.repository = repository
        self.userManager = userManager
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
        register(token: token, user: userManager.currentUser, timestamp: timestamp)
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        guard let token = currentToken() else {
            return
        }
        register(token: token, user: newUser, timestamp: timestamp)
    }

    private func register(token: PushToken, user: User, timestamp: Date) {
        let event = token.toEvent()
        let hackleUser = userManager.toHackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
    }
}
