//
//  AtomicReference.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation


class AtomicReference<T> {

    private let lock = ReadWriteLock(label: "io.hackle.AtomicReference.Lock")

    private var value: T

    init(value: T) {
        self.value = value
    }

    func get() -> T {
        lock.read {
            value
        }
    }

    func getAndSet(newValue: T) -> T {
        var oldValue: T!
        lock.write {
            oldValue = value
            value = newValue
        }
        return oldValue
    }

    func set(newValue: T) {
        lock.write {
            value = newValue
        }
    }

    func compareAndSet(expect: T, update: T) -> Bool where T: Equatable {
        var success = false
        lock.write {
            if value == expect {
                value = update
                success = true
            }
        }
        return success
    }
}
