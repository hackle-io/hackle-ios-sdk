//
//  AtomicDouble.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation

class AtomicDouble {

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

    func addAndGet(_ delta: Double) -> Double {
        var newValue: Double!
        lock.write {
            let oldValue = value
            newValue = oldValue + delta
            value = newValue
        }
        return newValue
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
