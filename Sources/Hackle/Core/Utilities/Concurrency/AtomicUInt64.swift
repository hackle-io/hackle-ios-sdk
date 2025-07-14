//
//  AtomicUInt64.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/14/25.
//

import Foundation

class AtomicUInt64: AtomicNumber {
    typealias T = UInt64

    private let lock = ReadWriteLock(label: "io.hackle.AtomicUInt64.Lock")
    private var value: UInt64

    init(value: UInt64) {
        self.value = value
    }

    func get() -> UInt64 {
        lock.read {
            value
        }
    }
    
    func set(_ value: UInt64) {
        lock.write {
            self.value = value
        }
    }
    
    func setAndGet(_ value: UInt64) -> UInt64 {
        set(value)
        return value
    }

    @discardableResult
    func addAndGet(_ delta: UInt64) -> UInt64 {
        var newValue: UInt64!
        lock.write {
            let oldValue = value
            newValue = oldValue + delta
            value = newValue
        }
        return newValue
    }
    
    @discardableResult
    func incrementAndGet() -> UInt64 {
        addAndGet(1)
    }
}

