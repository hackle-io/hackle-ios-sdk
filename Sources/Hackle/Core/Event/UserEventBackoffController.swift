//
//  UserEventBackoffController.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/11/25.
//

import Foundation

protocol UserEventBackoffController {
    func checkResponse(_ isSuccess: Bool)
    func isAllowNextFlush() -> Bool
}

class DefaultUserEventBackoffController: UserEventBackoffController {
    private let userEventRetryInterval: TimeInterval
    private let clock: Clock
    private var nextFlushAllowDate: AtomicReference<Date?> = AtomicReference(value: nil)
    private var failureCount: AtomicUInt64 = AtomicUInt64(value: 0)
    
    init(userEventRetryInterval: TimeInterval, clock: Clock) {
        self.userEventRetryInterval = userEventRetryInterval
        self.clock = clock
    }
    
    func checkResponse(_ isSuccess: Bool) {
        let count = isSuccess ? failureCount.setAndGet(0) : failureCount.addAndGet(1)
        calculateNextFlushDate(failureCount: count)
    }
    
    func isAllowNextFlush() -> Bool {
        guard let nextFlushAllowDate = nextFlushAllowDate.get() else {
            return true
        }
        
        let now = clock.now()
        if now < nextFlushAllowDate {
            Log.debug("Skipping flush. Next flush date: \(nextFlushAllowDate), current time: \(now)")
            return false
        }
        
        return true
    }
    
    private func calculateNextFlushDate(failureCount: UInt64) {
        if failureCount == 0 {
            nextFlushAllowDate.set(newValue: nil)
        } else {
            let exponential = pow(2.0, Double(failureCount) - 1)
            let intervalSeconds = min(exponential * userEventRetryInterval, userEventRetryMaxInterval)
            nextFlushAllowDate.set(newValue: clock.now().addingTimeInterval(intervalSeconds))
        }
    }
}

