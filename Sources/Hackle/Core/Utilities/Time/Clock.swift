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

    static let shared = SystemClock()

    func now() -> Date {
        Date()
    }

    func currentMillis() -> Int64 {
        now().epochMillis
    }

    func tick() -> UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1000 * 1000 * 1000)
    }
    
    /// daysToMillis
    /// - Parameter days: 변환 할 일자 수
    /// - Returns: days를 millisecond로 변환한 값
    func daysToMillis(days: Int) -> Int64 {
        Int64(days) * 24 * 60 * 60 * 1000
    }
}
