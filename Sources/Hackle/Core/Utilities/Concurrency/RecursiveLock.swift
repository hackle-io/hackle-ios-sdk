//
//  RecursiveLock.swift
//  Hackle
//

import Foundation

final class RecursiveLock: @unchecked Sendable {

    private let lock = NSRecursiveLock()

    init(label: String) {
        lock.name = label
    }

    @discardableResult
    func locked<T>(_ block: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try block()
    }
}
