//
//  Clock.swift
//  Hackle
//
//  Created by yong on 2023/01/19.
//

import Foundation


protocol Clock {

    func currentMillis() -> Int64

    func tick() -> UInt64
}

class SystemClock: Clock {

    static let instance = SystemClock()

    func currentMillis() -> Int64 {
        Date().epochMillis
    }

    func tick() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds
    }
}
