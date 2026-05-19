//
//  RecursiveLock.swift
//  Hackle
//

import Foundation

final class RecursiveLock: @unchecked Sendable {

    private let recursiveLock = NSRecursiveLock()

    init(label: String) {
        recursiveLock.name = label
    }

    @discardableResult
    func lock<T>(_ block: () throws -> T) rethrows -> T {
        recursiveLock.lock()
        defer { recursiveLock.unlock() }
        return try block()
    }
}
