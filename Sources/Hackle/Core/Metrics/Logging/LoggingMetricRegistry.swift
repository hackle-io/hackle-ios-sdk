//
//  LoggingMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class LoggingMetricRegistry: FlushMetricRegistry {

    override init(scheduler: Scheduler, pushInterval: TimeInterval) {
        super.init(scheduler: scheduler, pushInterval: pushInterval)
        start()
    }

    override func flushMetrics(metrics: [Metric]) {
        metrics
            .sorted { m1, m2 in
                m1.id.name < m2.id.name
            }
            .forEach { metric in
                log(metric: metric)
            }

    }

    private func log(metric: Metric) {
        let metricLog = "\(metric.id.name) \(metric.id.tags) " + metric.measure()
            .map { it in
                "\(it.field.rawValue)=\(it.value)"
            }
            .joined(separator: " ")
        Log.info(metricLog)
    }
}
