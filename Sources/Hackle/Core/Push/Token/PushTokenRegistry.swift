import Foundation

/// This registry manages PushToken for application lifecycle scope.
/// Persistent storage of PushToken is managed by `PushTokenManager`
protocol PushTokenRegistry {
    func registeredToken() -> PushToken?
    func register(token: PushToken, timestamp: Date)
    func flush()
}


class DefaultPushTokenRegistry: PushTokenRegistry, @unchecked Sendable {

    static let shared = DefaultPushTokenRegistry()

    private let listeners: AtomicReference<[PushTokenListener]> = AtomicReference(value: [])
    private let token: AtomicReference<PushToken?> = AtomicReference(value: nil)

    func addListener(listener: PushTokenListener) {
        listeners.set(newValue: listeners.get() + [listener])
    }

    func registeredToken() -> PushToken? {
        token.get()
    }

    func register(token: PushToken, timestamp: Date) {
        let currentToken = self.token.getAndSet(newValue: token)
        if token == currentToken {
            return
        }
        publishTokenRegistered(token: token, timestamp: timestamp)
    }

    func flush() {
        guard let token = registeredToken() else {
            return
        }
        publishTokenRegistered(token: token, timestamp: Date())
    }

    private func publishTokenRegistered(token: PushToken, timestamp: Date) {
        for listener in listeners.get() {
            listener.onTokenRegistered(token: token, timestamp: timestamp)
        }
    }
}
