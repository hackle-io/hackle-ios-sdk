//
//  SafeLock.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/16/26.
//

import Foundation

final class SafeLock: @unchecked Sendable {

    private let lock = NSLock()

    init(label: String) {
        lock.name = label
    }

    @discardableResult
    func lock<T>(_ block: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try block()
    }
}
