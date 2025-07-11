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
    private let clock: Clock
    private var nextFlushAllowDate: Int64? = nil
    private var failureCount: UInt = 0
    
    init(clock: Clock) {
        self.clock = clock
    }
    
    func checkResponse(_ isSuccess: Bool) {
        failureCount = isSuccess ? 0 : failureCount + 1
        calculateNextFlushDate()
    }
    
    func isAllowNextFlush() -> Bool {
        guard let nextFlushAllowDate = nextFlushAllowDate else {
            return true
        }
        
        let now = clock.currentMillis()
        if now < nextFlushAllowDate {
            Log.debug("Skipping flush. Next flush date: \(nextFlushAllowDate), current time: \(now)")
            return false
        }
        
        return true
    }
    
    private func calculateNextFlushDate() {
        if failureCount == 0 {
            nextFlushAllowDate = nil
        } else {
            guard let interval = pow(2.0, Double(failureCount) - 1).toInt64OrNil() else {
                nextFlushAllowDate = nil
                return
            }
            let intervalMilis = min(interval * userEventRetryInterval, userEventRetryMaxInterval)
            nextFlushAllowDate = clock.currentMillis() + intervalMilis
        }
    }
}

