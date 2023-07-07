//
//  CumulativeCounter.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation

class CumulativeCounter: Counter {

    let id: MetricId

    private let value = AtomicInt64(value: 0)

    init(id: MetricId) {
        self.id = id
    }

    func count() -> Int64 {
        value.get()
    }

    func increment(_ delta: Int64) {
        let _ = value.addAndGet(delta)
    }
}
