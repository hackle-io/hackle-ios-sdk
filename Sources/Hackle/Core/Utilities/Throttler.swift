import Foundation

class Throttler {
    
    private let interval: TimeInterval
    
    private let dispatchQueue: DispatchQueue
    private let executeLock: NSLock = NSLock()
    
    private var executedDate: Date?
    
    init(interval: TimeInterval, dispatchQueue: DispatchQueue = .main) {
        self.interval = interval
        self.dispatchQueue = dispatchQueue
    }
    
    func callAsFunction(block: @escaping (Bool) -> Void) {
        executeLock.lock()
        defer { executeLock.unlock() }
        
        var throttled = false
        if let executedDate = executedDate {
            let timeBetween = -(executedDate.timeIntervalSinceNow)
            if timeBetween < interval {
                throttled = true
            }
        }
        
        if !throttled {
            executedDate = Date()
        }
        publish(throttled: throttled, block: block)
    }
    
    private func publish(throttled: Bool, block: @escaping (Bool) -> Void) {
        dispatchQueue.async {
            block(throttled)
        }
    }
}
