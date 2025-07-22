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
    private let lock = ReadWriteLock(label: "io.hackle.DefaultUserEventBackoffController.Lock")
    private var nextFlushAllowDate: Date? = nil
    private var failureCount: UInt = 0
    
    init(userEventRetryInterval: TimeInterval, clock: Clock) {
        self.userEventRetryInterval = userEventRetryInterval
        self.clock = clock
    }
    
    func checkResponse(_ isSuccess: Bool) {
        lock.write {
            if isSuccess {
                failureCount = 0
            } else {
                failureCount += 1
                Metrics.counter(name: "user.event.backoff", tags: ["count": "\(failureCount)"]).increment()
            }
            calculateNextFlushDate()
        }
    }
    
    func isAllowNextFlush() -> Bool {
        lock.read {
            guard let nextFlushAllowDate = nextFlushAllowDate else {
                return true
            }
            
            let now = clock.now()
            if now < nextFlushAllowDate {
                Log.debug("Skipping flush. Next flush date: \(nextFlushAllowDate), current time: \(now)")
                return false
            }
            
            return true
        }
    }
    
    private func calculateNextFlushDate() {
        if failureCount == 0 {
            nextFlushAllowDate = nil
        } else {
            let exponential = pow(2.0, Double(failureCount) - 1)
            let intervalSeconds = min(exponential * userEventRetryInterval, userEventRetryMaxInterval)
            nextFlushAllowDate = clock.now().addingTimeInterval(intervalSeconds)
        }
    }
}

