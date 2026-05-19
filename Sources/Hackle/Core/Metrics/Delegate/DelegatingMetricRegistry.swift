//
//  DelegatingMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation


class DelegatingMetricRegistry: MetricRegistry, @unchecked Sendable {

    private let registries = AtomicReference<Set<MetricRegistry>>(value: [])

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
        for registry in registries.get() {
            metric.add(registry: registry)
        }
    }

    func add(registry: MetricRegistry) {
        if registry is DelegatingMetricRegistry {
            return
        }

        let snapshot = registries.get()
        guard !snapshot.contains(registry) else { return }
        var updated = snapshot
        updated.insert(registry)
        registries.set(newValue: updated)

        for metric in metrics {
            if let delegatingMetric = metric as? DelegatingMetric {
                delegatingMetric.add(registry: registry)
            }
        }
    }

    func clear() {
        registries.set(newValue: [])
    }
}
