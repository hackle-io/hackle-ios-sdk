//
//  NoopCounter.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation


class NoopCounter: Counter {

    let id: MetricId

    init(id: MetricId) {
        self.id = id
    }

    func count() -> Int64 {
        0
    }

    func increment(_ delta: Int64) {
    }
}
