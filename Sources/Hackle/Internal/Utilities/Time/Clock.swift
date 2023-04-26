//
//  Clock.swift
//  Hackle
//
//  Created by yong on 2023/01/19.
//

import Foundation


protocol Clock {

    func now() -> Date

    func currentMillis() -> Int64

    func tick() -> UInt64
}

class SystemClock: Clock {

    static let instance = SystemClock()

    func now() -> Date {
        Date()
    }

    func currentMillis() -> Int64 {
        now().epochMillis
    }

    func tick() -> UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1000 * 1000 * 1000)
    }
}
