//
//  NoopTimer.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation


class NoopTimer: Timer {

    let id: MetricId

    init(id: MetricId) {
        self.id = id
    }

    func count() -> Int64 {
        0
    }

    func totalTime(unit: TimeUnit) -> Double {
        0
    }

    func max(unit: TimeUnit) -> Double {
        0
    }

    func mean(unit: TimeUnit) -> Double {
        0
    }

    func record(amount: Double, unit: TimeUnit) {
    }
}
