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
    
    func callAsFunction(block: @escaping () -> Void) {
        callAsFunction { throttled, quotesInScope, leftTimeIntervalInScope in
            block()
        }
    }
    
    func callAsFunction(block: @escaping (Bool) -> Void) {
        callAsFunction { throttled, quotesInScope, leftTimeIntervalInScope in
            block(throttled)
        }
    }
    
    func callAsFunction(block: @escaping (Bool, Int64, TimeInterval) -> Void) {
        executeLock.lock()
        defer { executeLock.unlock() }
        
        let executeDate = Date()
        var throttled = false
        var quotesInScope = limitInScope - executedCountInScope.get()
        var leftTimeIntervalInScope: TimeInterval?
        
        if let firstExecutedDate = firstExecutedDateInScope {
            let endScopeDate = firstExecutedDate + interval
            leftTimeIntervalInScope = endScopeDate.timeIntervalSince(executeDate)
            
            if executeDate < endScopeDate {
                if quotesInScope <= 0 {
                    throttled = true
                }
            } else {
                quotesInScope = limitInScope
                leftTimeIntervalInScope = nil
                firstExecutedDateInScope = nil
                executedCountInScope.set(0)
            }
        }
        
        if !throttled {
            if firstExecutedDateInScope == nil {
                firstExecutedDateInScope = Date()
            }
            executedCountInScope.increment()
        }
        
        dispatchQueue.async {
            block(throttled, quotesInScope, leftTimeIntervalInScope ?? self.interval)
        }
    }
}
