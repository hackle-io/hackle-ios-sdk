//
//  DelegatingMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation


class DelegatingMetricRegistry: MetricRegistry {

    private var registries = Set<MetricRegistry>()

    override func createCounter(id: MetricId) -> Counter {
        let counter = DelegatingCounter(id: id)
        addRegistries(metric: counter)
        return counter
    }

    override func createTimer(id: MetricId) -> Timer {
        let timer = DelegatingTimer(id: id)
        addRegistries(metric: timer)
        return timer
    }

    private func addRegistries(metric: DelegatingMetric) {
        for registry in registries {
            metric.add(registry: registry)
        }
    }

    func add(registry: MetricRegistry) {
        if registry is DelegatingMetricRegistry {
            return
        }

        lock {
            let (inserted, _) = registries.insert(registry)
            if inserted {
                for metric in metrics {
                    if let delegatingMetric = metric as? DelegatingMetric {
                        delegatingMetric.add(registry: registry)
                    }
                }
            }
        }
    }

    func clear() {
        lock {
            registries.removeAll()
        }
    }
}
