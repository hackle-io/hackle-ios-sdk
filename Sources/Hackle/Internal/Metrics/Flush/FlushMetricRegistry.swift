//
//  FlushMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class FlushMetricRegistry: PushMetricRegistry {

    final override func createCounter(id: MetricId) -> Counter {
        FlushCounter(id: id)
    }

    final override func createTimer(id: MetricId) -> Timer {
        FlushTimer(id: id)
    }

    final override func publish() {
        let metrics = metrics
            .compactMap { it in
                it as? FlushMetric
            }
            .map { it in
                it.flush()
            }

        flushMetrics(metrics: metrics)
    }

    func flushMetrics(metrics: [Metric]) {
    }
}
