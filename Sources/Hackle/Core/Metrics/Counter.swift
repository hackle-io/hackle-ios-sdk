//
//  Counter.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation


protocol Counter: Metric {

    func count() -> Int64

    func increment(_ delta: Int64)
}

extension Counter {

    func increment() {
        increment(1)
    }

    func measure() -> [Measurement] {
        [Measurement(field: MetricField.count, valueSupplier: { Double(count()) })]
    }
}

class CounterBuilder {

    private let name: String
    private var tags = [String: String]()

    init(name: String) {
        self.name = name
    }

    func tags(_ tags: [String: String]) -> CounterBuilder {
        for (key, value) in tags {
            self.tags[key] = value
        }
        return self
    }

    func tag(_ key: String, _ value: String) -> CounterBuilder {
        tags[key] = value
        return self
    }

    func register(registry: MetricRegistry) -> Counter {
        let id = MetricId(name: name, tags: tags, type: .counter)
        return registry.counter(id: id)
    }
}
