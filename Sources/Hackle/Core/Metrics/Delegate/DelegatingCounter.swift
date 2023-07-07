//
//  DelegatingCounter.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation

class DelegatingCounter: DelegatingMetric, Counter {

    let id: MetricId

    private let lock = ReadWriteLock(label: "io.hackle.DelegatingCounter.Lock")
    private let noopCounter: Counter
    private var _counters: [MetricRegistry: Counter]

    private var counters: [Counter] {
        let counters: [Counter] = Array(_counters.values)
        return counters
    }

    private var first: Counter {
        counters.first ?? noopCounter
    }

    init(id: MetricId) {
        self.id = id
        noopCounter = NoopCounter(id: id)
        _counters = [:]
    }

    func add(registry: MetricRegistry) {
        let newCounter = registry.counter(id: id)
        lock.write {
            var newCounters = _counters
            newCounters[registry] = newCounter
            _counters = newCounters
        }
    }

    func count() -> Int64 {
        first.count()
    }

    func increment(_ delta: Int64) {
        for metric in counters {
            metric.increment(delta)
        }
    }
}
