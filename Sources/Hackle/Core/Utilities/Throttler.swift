import Foundation

class Throttler {
    private let interval: TimeInterval
    private let limitInScope: Int64

    private let dispatchQueue: DispatchQueue
    private let executeLock = NSLock()
    
    private let executedCountInScope = AtomicInt64(value: 0)
    private var firstExecutedDateInScope: Date?
    
    init(intervalInSeconds interval: TimeInterval, limitInScope: Int = 1, dispatchQueue: DispatchQueue = .main) {
        self.interval = interval
        self.limitInScope = Int64(limitInScope)
        self.dispatchQueue = dispatchQueue
    }
    
    func callAsFunction(block: @escaping () -> Void, throttled: @escaping () -> Void) {
        callAsFunction(
            block: block,
            throttled: { quotesInScope, leftTimeIntervalInScope in
                throttled()
            }
        )
    }
    
    func callAsFunction(block: @escaping () -> Void, throttled: @escaping (Int64, TimeInterval) -> Void) {
        executeLock.lock()
        defer { executeLock.unlock() }
        
        let executeDate = Date()
        var isThrottled = false
        var quotesInScope = limitInScope - executedCountInScope.get()
        var leftTimeIntervalInScope: TimeInterval?
        
        if let firstExecutedDate = firstExecutedDateInScope {
            let endScopeDate = firstExecutedDate + interval
            leftTimeIntervalInScope = endScopeDate.timeIntervalSince(executeDate)
            
            if executeDate < endScopeDate {
                if quotesInScope <= 0 {
                    isThrottled = true
                }
            } else {
                quotesInScope = limitInScope
                leftTimeIntervalInScope = nil
                firstExecutedDateInScope = nil
                executedCountInScope.set(0)
            }
        }
        
        if !isThrottled {
            if firstExecutedDateInScope == nil {
                firstExecutedDateInScope = Date()
            }
            executedCountInScope.incrementAndGet()
        }
        
        dispatchQueue.async {
            if !isThrottled {
                block()
            } else {
                throttled(quotesInScope, leftTimeIntervalInScope ?? self.interval)
            }
        }
    }
}
