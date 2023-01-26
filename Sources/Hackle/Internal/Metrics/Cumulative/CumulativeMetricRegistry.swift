//
//  CumulativeMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/24.
//

import Foundation


class CumulativeMetricRegistry: MetricRegistry {
    override func createCounter(id: MetricId) -> Counter {
        CumulativeCounter(id: id)
    }

    override func createTimer(id: MetricId) -> Timer {
        CumulativeTimer(id: id)
    }
}
