//
//  FixedClock.swift
//  HackleTests
//
//  Created by yong on 2023/06/25.
//

import Foundation
@testable import Hackle

class FixedClock: Clock {

    private let date: Date

    init(date: Date) {
        self.date = date
    }

    func now() -> Date {
        date
    }

    func currentMillis() -> Int64 {
        date.epochMillis
    }

    func tick() -> UInt64 {
        UInt64(date.timeIntervalSince1970 * 1000 * 1000 * 1000)
    }
}
