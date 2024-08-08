import Foundation

/// This registry manages PushToken for application lifecycle scope.
/// Persistent storage of PushToken is managed by `PushTokenManager`
protocol PushTokenRegistry {
    func registeredToken() -> PushToken?
    func register(token: PushToken, timestamp: Date)
    func flush()
}


class DefaultPushTokenRegistry: PushTokenRegistry {

    static let shared = DefaultPushTokenRegistry()

    private let lock = ReadWriteLock(label: "io.hackle.GlobalPushTokenRegistry")
    private var listeners: [PushTokenListener] = []
    private var token: PushToken? = nil

    func addListener(listener: PushTokenListener) {
        listeners.append(listener)
    }

    func registeredToken() -> PushToken? {
        lock.read { () -> PushToken? in
            token
        }
    }

    func register(token: PushToken, timestamp: Date) {
        lock.write { () -> () in
            let currentToken = self.token
            self.token = token
            if token == currentToken {
                return
            }
            publishTokenRegistered(token: token, timestamp: timestamp)
        }
    }

    func flush() {
        guard let token = registeredToken() else {
            return
        }
        publishTokenRegistered(token: token, timestamp: Date())
    }

    private func publishTokenRegistered(token: PushToken, timestamp: Date) {
        for listener in listeners {
            listener.onTokenRegistered(token: token, timestamp: timestamp)
        }
    }
}
