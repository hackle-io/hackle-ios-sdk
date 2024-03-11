import Foundation

protocol PushTokenRegistry {
    func currentToken() -> PushToken?
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

    func currentToken() -> PushToken? {
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
            onTokenRegistered(token: token, timestamp: timestamp)
        }
    }

    func flush() {
        guard let token = currentToken() else {
            return
        }
        onTokenRegistered(token: token, timestamp: Date())
    }

    private func onTokenRegistered(token: PushToken, timestamp: Date) {
        for listener in listeners {
            listener.onTokenRegistered(token: token, timestamp: timestamp)
        }
    }
}
