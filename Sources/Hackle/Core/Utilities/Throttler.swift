import Foundation

class Throttler {
    let interval: TimeInterval
    
    private let dispatchQueue: DispatchQueue
    private let limitInScope: Int64

    private let throttleLock = NSLock()
    
    private let executedCountInScope = AtomicInt64(value: 0)
    private var firstExecutedDateInScope: Date = Date(timeIntervalSince1970: 0)
    
    init(intervalInSeconds interval: TimeInterval, dispatchQueue: DispatchQueue, limitInScope: Int = 1) {
        self.interval = interval
        self.limitInScope = Int64(limitInScope)
        self.dispatchQueue = dispatchQueue
    }
    
    func execute(action: @escaping () -> Void, throttled: @escaping () -> Void) {
        let isThrottled = throttle(executeDate: Date())
        dispatchQueue.async {
            if isThrottled {
                throttled()
            } else {
                action()
            }
        }
    }
    
    private func throttle(executeDate: Date) -> Bool {
        throttleLock.lock()
        defer { throttleLock.unlock() }
        
        expireCurrentScopeIfNeeded(executeDate: executeDate)
        let isThrottled = calculateQuotesInCurrentScope() <= 0
        if !isThrottled {
            executedCountInScope.incrementAndGet()
        }
        return isThrottled
    }
    
    private func expireCurrentScopeIfNeeded(executeDate: Date) {
        if isCurrentScopeExpired(date: executeDate) {
            executedCountInScope.set(0)
            firstExecutedDateInScope = executeDate
        }
    }
    
    private func isCurrentScopeExpired(date: Date) -> Bool {
        return calculateEndDateInCurrentScope().timeIntervalSince(date) < 0
    }
    
    private func calculateEndDateInCurrentScope() -> Date {
        return firstExecutedDateInScope + interval
    }
    
    private func calculateQuotesInCurrentScope() -> Int64 {
        return max(limitInScope - executedCountInScope.get(), 0)
    }
}
