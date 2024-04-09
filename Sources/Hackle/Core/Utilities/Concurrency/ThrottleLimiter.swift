import Foundation

protocol ThrottleLimiter {
    func tryAcquire() -> Bool
}

class ScopingThrottleLimiter: ThrottleLimiter {

    private let lock = ReadWriteLock(label: "io.hackle.ScopingThrottleLimiter.Lock")

    private let interval: TimeInterval
    private let limit: Int64
    private let clock: Clock

    private var currentScope: ThrottleScope? = nil

    init(interval: TimeInterval, limit: Int64, clock: Clock) {
        self.interval = interval
        self.limit = limit
        self.clock = clock
    }

    func tryAcquire() -> Bool {
        lock.write {
            let now = clock.now()
            let scope = refreshScopeIfNeeded(now: now)
            return scope.tryAcquire()
        }
    }

    private func refreshScopeIfNeeded(now: Date) -> ThrottleScope {
        if let currentScope = currentScope, !currentScope.isExpired(now: now) {
            return currentScope
        }
        let scope = ThrottleScope(expirationTime: now + interval, token: limit)
        currentScope = scope
        return scope
    }
}


private class ThrottleScope {
    private let expirationTime: Date
    private var token: Int64

    init(expirationTime: Date, token: Int64) {
        self.expirationTime = expirationTime
        self.token = token
    }

    func isExpired(now: Date) -> Bool {
        expirationTime < now
    }

    func tryAcquire() -> Bool {
        if token > 0 {
            token -= 1
            return true
        } else {
            return false
        }
    }
}
