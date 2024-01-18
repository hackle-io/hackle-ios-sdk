//
//  AtomicInt64.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation

class AtomicInt64 {

    private let lock = ReadWriteLock(label: "io.hackle.AtomicInt64.Lock")

    private var value: Int64

    init(value: Int64) {
        self.value = value
    }

    func get() -> Int64 {
        lock.read {
            value
        }
    }
    
    func set(_ value: Int64) {
        lock.write {
            self.value = value
        }
    }

    func addAndGet(_ delta: Int64) -> Int64 {
        var newValue: Int64!
        lock.write {
            let oldValue = value
            newValue = oldValue + delta
            value = newValue
        }
        return newValue
    }
    
    func add(_ delta: Int64) {
        set(value + delta)
    }
    

    func incrementAndGet() -> Int64 {
        addAndGet(1)
    }
    
    func increment() {
        add(1)
    }
}
