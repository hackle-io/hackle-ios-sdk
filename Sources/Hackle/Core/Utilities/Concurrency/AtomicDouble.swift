//
//  AtomicDouble.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation

class AtomicDouble: AtomicNumber {
    private let lock = ReadWriteLock(label: "io.hackle.AtomicDouble.Lock")
    private var value: Double

    init(value: Double) {
        self.value = value
    }

    func get() -> Double {
        lock.read {
            value
        }
    }
    
    func set(_ newValue: Double) {
        lock.write {
            value = newValue
        }
    }
    
    func setAndGet(_ value: Double) -> Double {
        set(value)
        return value
    }

    func addAndGet(_ delta: Double) -> Double {
        var newValue: Double!
        lock.write {
            let oldValue = value
            newValue = oldValue + delta
            value = newValue
        }
        return newValue
    }
    
    func incrementAndGet() -> Double {
        addAndGet(1)
    }

    func accumulateAndGet(_ n: Double, _ accumulator: (Double, Double) -> Double) -> Double {
        var prev, next: Double!
        lock.write {
            prev = value
            next = accumulator(prev, n)
            value = next
        }
        return next
    }
}
