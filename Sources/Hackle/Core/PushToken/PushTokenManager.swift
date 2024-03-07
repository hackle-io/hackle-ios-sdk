import Foundation

protocol PushTokenManager: UserListener {
    var registeredPushToken: String? { get }
    func initialize()
    func setPushToken(pushToken: String, timestamp: Date)
}

class DefaultPushTokenManager: PushTokenManager {
    private static let KEY_PUSH_TOKEN = "push_token"
    
    private let core: HackleCore
    private let preferences: KeyValueRepository
    private let userManager: UserManager
    private let dataSource: PushTokenDataSource
    
    private var _registeredPushToken: String? {
        get {
            return preferences.getString(key: DefaultPushTokenManager.KEY_PUSH_TOKEN)
        }
        set {
            if let value = newValue {
                preferences.putString(
                    key: DefaultPushTokenManager.KEY_PUSH_TOKEN,
                    value: value
                )
            } else {
                preferences.remove(key: DefaultPushTokenManager.KEY_PUSH_TOKEN)
            }
        }
    }
    var registeredPushToken: String? {
        get { return preferences.getString(key: DefaultPushTokenManager.KEY_PUSH_TOKEN) }
    }
    
    init(
        core: HackleCore,
        userManager: UserManager,
        preferences: KeyValueRepository,
        dataSource: PushTokenDataSource
    ) {
        self.core = core
        self.preferences = preferences
        self.userManager = userManager
        self.dataSource = dataSource
    }
    
    func initialize() {
        if let pushToken = dataSource.getPushToken() {
            setPushToken(pushToken: pushToken, timestamp: Date())
        }
    }
    
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        notifyPushTokenChanged(user: newUser, timestamp: timestamp)
    }
    
    func setPushToken(pushToken: String, timestamp: Date) {
        if _registeredPushToken == pushToken {
            Log.debug("Provided same push token.")
            return
        }
        
        _registeredPushToken = pushToken
        notifyPushTokenChanged(user: userManager.currentUser, timestamp: timestamp)
    }
    
    private func notifyPushTokenChanged(user: User, timestamp: Date) {
        guard let pushToken = _registeredPushToken else {
            Log.debug("Push token is empty.")
            return
        }
        
        let event = RegisterPushTokenEvent(token: pushToken).toTrackEvent()
        track(event: event, user: user, timestamp: timestamp)
    }
    
    private func track(event: Event, user: User, timestamp: Date) {
        let hackleUser = userManager.toHackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
        Log.debug("\(event.key) event queued.")
    }
}
