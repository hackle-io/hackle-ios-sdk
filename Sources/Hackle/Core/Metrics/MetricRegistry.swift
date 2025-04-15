//
//  MetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation

class MetricRegistry {

    let id = UUID()
    var name: String {
        "\(self)"
    }

    private let _lock = ReadWriteLock(label: "io.hackle.MetricRegistry.Lock")

    func lock(block: () -> ()) {
        _lock.write(block: block)
    }

    private var _metrics = [MetricId: Metric]()
    final var metrics: [Metric] {
        let metrics = Array(_metrics.values)
        return metrics
    }

    final func counter(name: String, tags: [String: String] = [:]) -> Counter {
        CounterBuilder(name: name).tags(tags).register(registry: self)
    }

    final func timer(name: String, tags: [String: String] = [:]) -> Timer {
        TimerBuilder(name: name).tags(tags).register(registry: self)
    }

    final func counter(id: MetricId) -> Counter {
        registerMetricIfNecessary(metricType: Counter.self, id: id, create: createCounter)
    }

    final func timer(id: MetricId) -> Timer {
        registerMetricIfNecessary(metricType: Timer.self, id: id, create: createTimer)
    }

    func createCounter(id: MetricId) -> Counter {
        NoopCounter(id: id)
    }

    func createTimer(id: MetricId) -> Timer {
        NoopTimer(id: id)
    }

    private func registerMetricIfNecessary<T>(metricType: T.Type, id: MetricId, create: (MetricId) -> Metric) -> T {
        let metric = getOrCreateMetric(id: id, create: create)
        return metric as! T
    }

    private func getOrCreateMetric(id: MetricId, create: (MetricId) -> Metric) -> Metric {
        var metric: Metric!
        lock {
            if let registeredMetric = _metrics[id] {
                metric = registeredMetric
            } else {
                let newMetric = create(id)
                _metrics[id] = newMetric
                metric = newMetric
            }
        }
        return metric
    }
}

extension MetricRegistry: Hashable {
    final public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(id)
    }

    public static func ==(lhs: MetricRegistry, rhs: MetricRegistry) -> Bool {
        lhs.id == rhs.id
    }
}
