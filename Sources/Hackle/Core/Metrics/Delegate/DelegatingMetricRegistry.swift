//
//  DelegatingMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation


class DelegatingMetricRegistry: MetricRegistry, @unchecked Sendable {

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
        // Holds `lock` (re-entered if called from createTimer/createCounter under
        // getOrCreateMetric). Without this, `registries` Set is iterated lock-free
        // while another thread mutates it via add(registry:) — the production race.
        lock.locked {
            for registry in registries {
                metric.add(registry: registry)
            }
        }
    }

    func add(registry: MetricRegistry) {
        if registry is DelegatingMetricRegistry {
            return
        }

        let inserted = lock.locked { registries.insert(registry).inserted }
        guard inserted else { return }

        for metric in metrics {
            if let delegatingMetric = metric as? DelegatingMetric {
                delegatingMetric.add(registry: registry)
            }
        }
    }

    func clear() {
        lock.locked {
            registries.removeAll()
        }
    }
}
